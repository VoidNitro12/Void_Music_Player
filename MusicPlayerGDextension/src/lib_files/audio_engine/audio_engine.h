#pragma once

#include "godot_cpp/classes/ref_counted.hpp"

#include "lib_files/error_logger/error_logger.h"

#include <string>

// miniaudio 0.11.25
#include <miniaudio.h>

class AudioEngine : public godot::RefCounted {
	GDCLASS(AudioEngine, godot::RefCounted)

protected:
	static void _bind_methods();

public:
	AudioEngine() = default;
	~AudioEngine() override = default;

    void set_up(const godot::Ref<ErrorLogger> &p_logger);

    void gd_play_audio(godot::String p_path);

    bool sound_exists();

    bool audio_is_playing();

    bool audio_ended();

    void pause();

    void resume();

    float get_playback_position();

    void seek_to(float p_seconds);

    void terminate();

private:
    ma_engine engine;

    ma_sound current_audio;

    bool sound_initialized = false;

    godot::Ref<ErrorLogger> logger;

    void play_audio(std::string p_path);

};