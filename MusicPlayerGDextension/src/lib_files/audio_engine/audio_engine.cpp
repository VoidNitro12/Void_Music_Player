#include "audio_engine.h"

#include "lib_files/error_logger/error_logger.h"

#include <string>
#include <format>
#include <atomic>

// miniaudio 0.11.25
#include <miniaudio.h>

using namespace godot;

// Bindings for GDscript
void AudioEngine::_bind_methods(){
    ClassDB::bind_method(D_METHOD("set_up", "error_logger"), &AudioEngine::set_up);
    ClassDB::bind_method(D_METHOD("terminate"), &AudioEngine::terminate);
    ClassDB::bind_method(D_METHOD("sound_exists"), &AudioEngine::sound_exists);
    ClassDB::bind_method(D_METHOD("is_playing"), &AudioEngine::audio_is_playing);
    ClassDB::bind_method(D_METHOD("play", "audio_path"), &AudioEngine::gd_play_audio);
    ClassDB::bind_method(D_METHOD("pause"), &AudioEngine::pause);
    ClassDB::bind_method(D_METHOD("resume"), &AudioEngine::resume);
    ClassDB::bind_method(D_METHOD("get_playback_position"), &AudioEngine::get_playback_position);
    ClassDB::bind_method(D_METHOD("seek", "seconds"), &AudioEngine::seek_to);
    ClassDB::bind_method(D_METHOD("set_volume", "volume"), &AudioEngine::set_volume);
    ClassDB::bind_method(D_METHOD("_emit_audio_ended"), &AudioEngine::_emit_audio_ended_signal);

    ADD_SIGNAL(MethodInfo("ended"));

}

// Function Definitions

AudioEngine::~AudioEngine(){
    terminate();
}

void AudioEngine::set_up(const godot::Ref<ErrorLogger> &p_logger){
    AudioEngine::logger = p_logger;

    ma_result result;

    result = ma_engine_init(NULL, &engine);
    if (result != MA_SUCCESS) {
        logger->log_error(
            ErrorLogger::LogLevel::WARN,
            godot::String::utf8("AudioEngine initialization failed")
        );
        return;
    }

    engine_initialized = true;
}

void AudioEngine::terminate(){
    if (sound_initialized){
    ma_sound_uninit(&current_audio);
    }

    if (engine_initialized){
        ma_engine_uninit(&engine);
    }
}

static void on_audio_ended(void *p_user_data, ma_sound *p_sound){
    AudioEngine *ended = static_cast<AudioEngine *>(p_user_data);
    
    ended->call_deferred("_emit_audio_ended");
    
}

void AudioEngine::_emit_audio_ended_signal(){
    emit_signal("ended");
}

void AudioEngine::play_audio(std::string p_path){
    ma_result result;

    if (sound_initialized){
        ma_sound_uninit(&current_audio);
    }

    result = ma_sound_init_from_file(&engine, p_path.c_str(), MA_SOUND_FLAG_STREAM | MA_SOUND_FLAG_ASYNC, NULL, NULL, &current_audio);

    if (result != MA_SUCCESS) {
        logger->log_error(
            ErrorLogger::LogLevel::ERROR,
            godot::String::utf8(std::format("Unable to play audio file at {}", p_path).c_str())
        );
        return;
    }

    sound_initialized = true;
    
    ma_sound_set_end_callback(&current_audio, on_audio_ended, this);

    ma_sound_start(&current_audio);
}

bool AudioEngine::sound_exists(){
    return sound_initialized;
}

bool AudioEngine::audio_is_playing(){
    if (!sound_initialized){
        return false;
   }

    if (ma_sound_is_playing(&current_audio)){
        return true;
    }

    return false;
}

bool AudioEngine::has_audio_ended(){
   if (!sound_initialized){
        return false;
   }

   if (ma_sound_at_end(&current_audio)){
        return true;
   }

    return false;
}

void AudioEngine::pause(){
    if (!sound_initialized){
        return;
   }

    ma_sound_stop(&current_audio);
}

void AudioEngine::resume(){
    if (!sound_initialized){
        return;
    }

    ma_sound_start(&current_audio);
}

float AudioEngine::get_playback_position(){
    if (!sound_initialized){
        return 0.0;
    }

    float pos;

    ma_sound_get_cursor_in_seconds(&current_audio, &pos);

    return pos;
}

void AudioEngine::seek_to(float p_seconds){
    if (!sound_initialized){
        return;
    }

    ma_sound_seek_to_second(&current_audio, p_seconds);
}

void AudioEngine::set_volume(float p_volume){
    if (!sound_initialized){
        return;
    }

    // Technically only sets the volume for current_audio and nothing else
    ma_sound_set_volume(&current_audio, p_volume);

}

void AudioEngine::gd_play_audio(godot::String p_path){
   play_audio(p_path.utf8().get_data());
}