#pragma once

// Custom miniaudio decoding backend for M4A/AAC/ALAC files via FFmpeg (libav).
// Requires FFmpeg 5.1+ (AVChannelLayout, swr_alloc_set_opts2).

#include <miniaudio.h>

#ifdef __cplusplus
extern "C" {
#endif

// Defined in m4a_decoder.cpp
extern ma_decoding_backend_vtable* ma_decoding_backend_ffmpeg;

#ifdef __cplusplus
}
#endif