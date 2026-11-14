// Just dont touch this file, wasnt willing to spend weeks learning this just to play
// m4a. maybe ill revisit this later (unlikely).
// Also the custom I/O bridge and all related avio parts might not be in use but 
// im leaving it in

// Custom miniaudio decoding backend for M4A/AAC/ALAC via FFmpeg.
// Structure follows miniaudio's official custom decoder pattern
// (extras/decoders/libvorbis, examples/custom_decoder_engine.c).

#include "m4a_decoder.h"

#include <miniaudio.h>

// Wrapping the headers in C incase the ffmpeg lib's dont have C++ linkage
extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
}

#include <algorithm>
#include <cstring>
#include <mutex>
#include <vector>

namespace {
    extern ma_data_source_vtable g_ffmpeg_ds_vtable;

    // Bridges miniaudio stream callbacks (stream-based init) into FFmpeg's AVIOContext.
    struct IOBridge {
        ma_read_proc onRead = nullptr;
        ma_seek_proc onSeek = nullptr;
        ma_tell_proc onTell = nullptr;
        void* pReadSeekTellUserData = nullptr;
    };

    struct FFmpegDecoder {
        // Must be first: the backend hands out ma_data_source* pointers.
        ma_data_source_base ds;

        AVFormatContext* format_ctx = nullptr;
        AVCodecContext*  codec_ctx  = nullptr;
        SwrContext*      swr_ctx    = nullptr;
        AVFrame*         frame      = nullptr;
        AVPacket*        packet     = nullptr;

        // Custom AVIO, used only for stream-based init.
        AVIOContext* avio_ctx = nullptr;
        uint8_t*     avio_buf = nullptr;
        IOBridge     io_bridge{};

        int       stream_index = -1;
        ma_uint32 channels     = 0;
        ma_uint32 sample_rate  = 0;
        ma_uint64 total_frames = 0;
        ma_uint64 cursor       = 0;
        bool      at_end       = false;

        // Decoded f32 interleaved PCM, drained across read calls.
        std::vector<float> pcm_buffer;
        size_t             pcm_buffer_pos = 0;

        // The resource manager may call read/seek from its job threads.
        std::mutex mutex;
    };

    //================ AVIO callbacks (stream-based init only)=======================

    int avio_read_cb(void* opaque, uint8_t* buf, int buf_size) {
        auto* b = static_cast<IOBridge*>(opaque);
        size_t bytes_read = 0;
        ma_result r = b->onRead(b->pReadSeekTellUserData, buf, static_cast<size_t>(buf_size), &bytes_read);
        if (r == MA_AT_END)        return AVERROR_EOF;
        if (r != MA_SUCCESS)       return AVERROR_UNKNOWN; 
        if (bytes_read == 0) return AVERROR_EOF;
        return static_cast<int>(bytes_read);
    }

    int64_t avio_seek_cb(void* opaque, int64_t offset, int whence) {
        auto* b = static_cast<IOBridge*>(opaque);

        ma_seek_origin origin;

        if ((whence & ~AVSEEK_FORCE) == AVSEEK_SIZE) {
            ma_int64 saved = 0, end = 0;

            if (b->onTell(b->pReadSeekTellUserData, &saved) != MA_SUCCESS)
                return AVERROR_UNKNOWN;

            if (b->onSeek(b->pReadSeekTellUserData, 0, ma_seek_origin_end) != MA_SUCCESS)
                return AVERROR_UNKNOWN;

            if (b->onTell(b->pReadSeekTellUserData, &end) != MA_SUCCESS) {
                b->onSeek(b->pReadSeekTellUserData, saved, ma_seek_origin_start);
                return AVERROR_UNKNOWN;
            }

            if (b->onSeek(b->pReadSeekTellUserData, saved, ma_seek_origin_start) != MA_SUCCESS)
                return AVERROR_UNKNOWN;

            return static_cast<int64_t>(end);
        }

        switch (whence & ~AVSEEK_FORCE) {
            case SEEK_SET: origin = ma_seek_origin_start;   break;
            case SEEK_CUR: origin = ma_seek_origin_current; break;
            case SEEK_END: origin = ma_seek_origin_end;     break;
            default: return AVERROR_UNKNOWN;
        }

        if (b->onSeek(b->pReadSeekTellUserData, offset, origin) != MA_SUCCESS) return AVERROR_UNKNOWN;

        ma_int64 pos = 0;
        
        if (b->onTell(b->pReadSeekTellUserData, &pos) != MA_SUCCESS) return AVERROR_UNKNOWN;

        return static_cast<int64_t>(pos);
    }

    // =================Lifecycle==================

    // Frees everything. Safe on partially-initialized state (only after ds init).
    void ffmpeg_decoder_destroy(FFmpegDecoder* d) {
        if (!d) return;
        if (d->frame)      av_frame_free(&d->frame);
        if (d->packet)     av_packet_free(&d->packet);
        if (d->swr_ctx)    swr_free(&d->swr_ctx);
        if (d->codec_ctx)  avcodec_free_context(&d->codec_ctx);
        if (d->format_ctx) avformat_close_input(&d->format_ctx);
        if (d->avio_ctx) {
            // The buffer may have been reallocated by FFmpeg, so free via the context.
            av_freep(&d->avio_ctx->buffer);
            avio_context_free(&d->avio_ctx);
        } else if (d->avio_buf) {
            av_freep(&d->avio_buf);
        }
        ma_data_source_uninit(&d->ds);
        delete d;
    }
    // Initializes the data source base and the reusable frame/packet.
    // On success: caller owns d and must eventually call ffmpeg_decoder_destroy.
    // On failure: d is already freed, caller must not touch it.
    ma_result ffmpeg_decoder_init(FFmpegDecoder* d) {
        ma_data_source_config ds_config = ma_data_source_config_init();
        ds_config.vtable = &g_ffmpeg_ds_vtable;

        ma_result result = ma_data_source_init(&ds_config, &d->ds);
        if (result != MA_SUCCESS) {
            delete d;
            return result;
        }

        d->frame  = av_frame_alloc();
        d->packet = av_packet_alloc();
        if (!d->frame || !d->packet) {
            ffmpeg_decoder_destroy(d);
            return MA_OUT_OF_MEMORY;
        }
        return MA_SUCCESS;
    }

    // Called after format_ctx is opened. 
    ma_result ffmpeg_init_common(FFmpegDecoder* d) {
        if (avformat_find_stream_info(d->format_ctx, nullptr) < 0) return MA_INVALID_FILE;

        d->stream_index = av_find_best_stream(d->format_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
        if (d->stream_index < 0) return MA_INVALID_FILE;

        AVStream* stream = d->format_ctx->streams[d->stream_index];

        // Only claim M4A-native codecs.
        // Widen this check (e.g. AV_CODEC_ID_OPUS) to claim more formats later, unlikely but in that case change the
        // file, header and folder name to a broader one else leave it as 'm4a_'
        AVCodecID codec_id = stream->codecpar->codec_id;
        if (codec_id != AV_CODEC_ID_AAC &&
            codec_id != AV_CODEC_ID_AAC_LATM && // This codec is likely not needed but i'm adding it none the less
            codec_id != AV_CODEC_ID_ALAC) {
            return MA_NOT_IMPLEMENTED;
        }

        const AVCodec* codec = avcodec_find_decoder(codec_id);
        if (!codec) return MA_NO_BACKEND;

        d->codec_ctx = avcodec_alloc_context3(codec);
        if (!d->codec_ctx) return MA_OUT_OF_MEMORY;

        if (avcodec_parameters_to_context(d->codec_ctx, stream->codecpar) < 0) return MA_ERROR;
        if (avcodec_open2(d->codec_ctx, codec, nullptr) < 0) return MA_ERROR;

        d->channels   = static_cast<ma_uint32>(d->codec_ctx->ch_layout.nb_channels);
        d->sample_rate = static_cast<ma_uint32>(d->codec_ctx->sample_rate);

        // Total frame count from stream or container duration. 0 if unknown.
        if (stream->duration != AV_NOPTS_VALUE) {
            double secs = static_cast<double>(stream->duration) * av_q2d(stream->time_base);
            d->total_frames = static_cast<ma_uint64>(secs * d->sample_rate + 0.5);
        } else if (d->format_ctx->duration != AV_NOPTS_VALUE) {
            double secs = static_cast<double>(d->format_ctx->duration) / AV_TIME_BASE;
            d->total_frames = static_cast<ma_uint64>(secs * d->sample_rate + 0.5);
        }

        // Convert the codec's native format (usually planar float) into
        // interleaved f32 at the source rate. The engine resamples as needed.
        if (swr_alloc_set_opts2(
                &d->swr_ctx,
                &d->codec_ctx->ch_layout, AV_SAMPLE_FMT_FLT, d->sample_rate,
                &d->codec_ctx->ch_layout, d->codec_ctx->sample_fmt, d->codec_ctx->sample_rate,
                0, nullptr) < 0) return MA_ERROR;
        if (swr_init(d->swr_ctx) < 0) return MA_ERROR;

        return MA_SUCCESS;
    }

    // ============================Decoding=========================

    // Decodes one frame into pcm_buffer. MA_SUCCESS / MA_AT_END / MA_ERROR.
    // Caller must hold d->mutex.
    ma_result ffmpeg_decode_next(FFmpegDecoder* d) {
        if (d->at_end) return MA_AT_END;

        for (;;) {
            int ret = avcodec_receive_frame(d->codec_ctx, d->frame);

            if (ret == 0) {
                // Size the output for the worst case (resampler delay + samples).
                int max_out = static_cast<int>(av_rescale_rnd(
                    swr_get_delay(d->swr_ctx, d->codec_ctx->sample_rate) + d->frame->nb_samples,
                    d->sample_rate, d->codec_ctx->sample_rate, AV_ROUND_UP));

                d->pcm_buffer.resize(static_cast<size_t>(max_out) * d->channels);
                uint8_t* out_planes[1] = { reinterpret_cast<uint8_t*>(d->pcm_buffer.data()) };

                int n = swr_convert(d->swr_ctx,
                    out_planes, max_out,
                    const_cast<const uint8_t**>(d->frame->data), d->frame->nb_samples);
                av_frame_unref(d->frame);

                if (n < 0) return MA_ERROR;
                d->pcm_buffer.resize(static_cast<size_t>(n) * d->channels);
                d->pcm_buffer_pos = 0;
                return MA_SUCCESS;
            }

            if (ret == AVERROR_EOF) { d->at_end = true; return MA_AT_END; }
            if (ret != AVERROR(EAGAIN)) return MA_ERROR;

            // Codec wants input: pull the next packet from the container.
            for (;;) {
                int pret = av_read_frame(d->format_ctx, d->packet);

                if (pret == AVERROR_EOF) {
                    // Flush the decoder so buffered frames get drained.
                    avcodec_send_packet(d->codec_ctx, nullptr);
                    break;
                }
                if (pret < 0) return MA_ERROR;

                if (d->packet->stream_index != d->stream_index) {
                    av_packet_unref(d->packet);
                    continue;
                }

                int sret = avcodec_send_packet(d->codec_ctx, d->packet);
                av_packet_unref(d->packet);
                if (sret < 0 && sret != AVERROR(EAGAIN)) return MA_ERROR;
                break;
            }
        }
    }

    ma_result ffmpeg_read_pcm_frames(FFmpegDecoder* d, void* pFramesOut, ma_uint64 frameCount, ma_uint64* pFramesRead) {
        if (pFramesRead) *pFramesRead = 0;
        if (frameCount == 0) return MA_INVALID_ARGS;

        std::lock_guard<std::mutex> lock(d->mutex);
        auto* out = static_cast<float*>(pFramesOut);
        ma_uint64 total_read = 0;

        while (total_read < frameCount) {
            // Drain the internal buffer first.
            if (d->pcm_buffer_pos < d->pcm_buffer.size()) {
                size_t samples_avail = d->pcm_buffer.size() - d->pcm_buffer_pos;
                size_t frames_avail  = samples_avail / d->channels;
                size_t frames_copy   = std::min(frames_avail, static_cast<size_t>(frameCount - total_read));
                size_t samples_copy  = frames_copy * d->channels;

                std::memcpy(out, d->pcm_buffer.data() + d->pcm_buffer_pos, samples_copy * sizeof(float));
                out               += samples_copy;
                d->pcm_buffer_pos += samples_copy;
                total_read        += frames_copy;
                d->cursor         += frames_copy;
                continue;
            }

            ma_result result = ffmpeg_decode_next(d);
            if (result == MA_AT_END) break;
            if (result != MA_SUCCESS) return result;
        }

        if (pFramesRead) *pFramesRead = total_read;
        if (total_read == 0) return d->at_end ? MA_AT_END : MA_SUCCESS;
        return MA_SUCCESS;
    }

    ma_result ffmpeg_seek_to_pcm_frame(FFmpegDecoder* d, ma_uint64 frameIndex) {
        std::lock_guard<std::mutex> lock(d->mutex);

        if (!d->format_ctx || d->stream_index < 0) return MA_INVALID_OPERATION;
        AVStream* stream = d->format_ctx->streams[d->stream_index];

        // Convert the frame index to a stream timestamp.
        AVRational frame_rate_q = { 1, static_cast<int>(d->sample_rate) };
        int64_t ts = av_rescale_q(static_cast<int64_t>(frameIndex), frame_rate_q, stream->time_base);

        // Snap to the nearest keyframe at or before the target. AAC keyframes
        // are seconds apart, so playback may resume slightly early. Fine for
        // the music player
        if (av_seek_frame(d->format_ctx, d->stream_index, ts, AVSEEK_FLAG_BACKWARD) < 0) return MA_ERROR;

        // Buffered frames belong to the old position.
        avcodec_flush_buffers(d->codec_ctx);
        d->pcm_buffer.clear();
        d->pcm_buffer_pos = 0;
        d->cursor = frameIndex;
        d->at_end = false;
        return MA_SUCCESS;
    }

    ma_result ffmpeg_get_data_format(FFmpegDecoder* d, ma_format* pFormat, ma_uint32* pChannels, ma_uint32* pSampleRate, ma_channel* pChannelMap, size_t channelMapCap) {
        if (pFormat)    *pFormat    = ma_format_f32;
        if (pChannels)  *pChannels  = d->channels;
        if (pSampleRate) *pSampleRate = d->sample_rate;
        if (pChannelMap) {
            // Zeroed entries are MA_CHANNEL_NONE: miniaudio applies its default
            // mapping. Fill in the obvious ones for mono/stereo.
            std::memset(pChannelMap, 0, channelMapCap * sizeof(ma_channel));
            for (size_t i = 0; i < d->channels && i < channelMapCap; ++i) {
                pChannelMap[i] = (d->channels == 1)
                    ? MA_CHANNEL_MONO
                    : static_cast<ma_channel>(MA_CHANNEL_FRONT_LEFT + i);
            }
        }
        return MA_SUCCESS;
    }

    // ma_data_source vtable 

    ma_result ffmpeg_ds_read(ma_data_source* pDataSource, void* pFramesOut, ma_uint64 frameCount, ma_uint64* pFramesRead) {
        return ffmpeg_read_pcm_frames(reinterpret_cast<FFmpegDecoder*>(pDataSource), pFramesOut, frameCount, pFramesRead);
    }

    ma_result ffmpeg_ds_seek(ma_data_source* pDataSource, ma_uint64 frameIndex) {
        return ffmpeg_seek_to_pcm_frame(reinterpret_cast<FFmpegDecoder*>(pDataSource), frameIndex);
    }

    ma_result ffmpeg_ds_get_data_format(ma_data_source* pDataSource, ma_format* pFormat, ma_uint32* pChannels, ma_uint32* pSampleRate, ma_channel* pChannelMap, size_t channelMapCap) {
        return ffmpeg_get_data_format(reinterpret_cast<FFmpegDecoder*>(pDataSource), pFormat, pChannels, pSampleRate, pChannelMap, channelMapCap);
    }

    ma_result ffmpeg_ds_get_cursor(ma_data_source* pDataSource, ma_uint64* pCursor) {
        auto* d = reinterpret_cast<FFmpegDecoder*>(pDataSource);
        std::lock_guard<std::mutex> lock(d->mutex);
        *pCursor = d->cursor;
        return MA_SUCCESS;
    }

    ma_result ffmpeg_ds_get_length(ma_data_source* pDataSource, ma_uint64* pLength) {
        auto* d = reinterpret_cast<FFmpegDecoder*>(pDataSource);
        std::lock_guard<std::mutex> lock(d->mutex);
        *pLength = d->total_frames;
        return MA_SUCCESS;
    }

    // Order matters: read, seek, get_data_format, get_cursor, get_length, onSetLooping, flags.
    // if the miniaudio version is ever changed make check this for vtable reordering
    ma_data_source_vtable g_ffmpeg_ds_vtable = {
        ffmpeg_ds_read,
        ffmpeg_ds_seek,
        ffmpeg_ds_get_data_format,
        ffmpeg_ds_get_cursor,
        ffmpeg_ds_get_length,
        NULL,   // onSetLooping 
        0       // flags 
    };

    // ===========Backend vtable: only the init variants and uninit live here.=================

    ma_result ffmpeg_backend_init(void* /*pUserData*/, ma_read_proc onRead, ma_seek_proc onSeek, ma_tell_proc onTell, void* pReadSeekTellUserData, const ma_decoding_backend_config* pConfig, const ma_allocation_callbacks* /*pAllocationCallbacks*/, ma_data_source** ppBackend) {
        if (!onRead || !onSeek) return MA_INVALID_ARGS;

        auto* d = new (std::nothrow) FFmpegDecoder();
        if (!d) return MA_OUT_OF_MEMORY;

        ma_result result = ffmpeg_decoder_init(d);
        if (result != MA_SUCCESS) { return result; }

        d->io_bridge = { onRead, onSeek, onTell, pReadSeekTellUserData };

        static constexpr int AVIO_BUF_SIZE = 65536;
        d->avio_buf = static_cast<uint8_t*>(av_malloc(AVIO_BUF_SIZE));
        d->avio_ctx = avio_alloc_context(d->avio_buf, AVIO_BUF_SIZE, 0, &d->io_bridge, avio_read_cb, nullptr, avio_seek_cb);
        if (!d->avio_ctx) { ffmpeg_decoder_destroy(d); return MA_OUT_OF_MEMORY; }

        d->format_ctx = avformat_alloc_context();
        if (!d->format_ctx) { ffmpeg_decoder_destroy(d); return MA_OUT_OF_MEMORY; }
        d->format_ctx->pb = d->avio_ctx;
        d->format_ctx->flags |= AVFMT_FLAG_CUSTOM_IO;

        if (avformat_open_input(&d->format_ctx, nullptr, nullptr, nullptr) < 0) {
            ffmpeg_decoder_destroy(d);
            return MA_INVALID_FILE;
        }

        result = ffmpeg_init_common(d);
        if (result != MA_SUCCESS) { ffmpeg_decoder_destroy(d); return result; }

        *ppBackend = &d->ds;
        return MA_SUCCESS;
    }

    ma_result ffmpeg_backend_init_file(void* /*pUserData*/, const char* pFilePath, const ma_decoding_backend_config* /*pConfig*/, const ma_allocation_callbacks* /*pAllocationCallbacks*/, ma_data_source** ppBackend) {
        auto* d = new (std::nothrow) FFmpegDecoder();
        if (!d) return MA_OUT_OF_MEMORY;

        ma_result result = ffmpeg_decoder_init(d);
        if (result != MA_SUCCESS) { return result; }

        // FFmpeg's file protocol handles UTF-8 paths on Windows internally.
        if (avformat_open_input(&d->format_ctx, pFilePath, nullptr, nullptr) < 0) {
            ffmpeg_decoder_destroy(d);
            return MA_INVALID_FILE;
        }

        result = ffmpeg_init_common(d);
        if (result != MA_SUCCESS) { ffmpeg_decoder_destroy(d); return result; }

        *ppBackend = &d->ds;
        return MA_SUCCESS;
    }

    void ffmpeg_backend_uninit(void* /*pUserData*/, ma_data_source* pBackend, const ma_allocation_callbacks* /*pAllocationCallbacks*/) {
        ffmpeg_decoder_destroy(reinterpret_cast<FFmpegDecoder*>(pBackend));
    }

    ma_decoding_backend_vtable g_ffmpeg_backend_vtable = {
        ffmpeg_backend_init,       /* onInit */
        ffmpeg_backend_init_file,  /* onInitFile */
        NULL,                      /* onInitFileW */
        NULL,                      /* onInitMemory */
        ffmpeg_backend_uninit      /* onUninit */
    };

} // namespace

extern "C" {
ma_decoding_backend_vtable* ma_decoding_backend_ffmpeg = &g_ffmpeg_backend_vtable;
}