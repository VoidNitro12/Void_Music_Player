#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/audio_stream.hpp"

using namespace godot;

class Song : public RefCounted {
	GDCLASS(Song, RefCounted)

private: 
    String path;
    String artist;
    String album;
    int64_t release_year;
    real_t raw_length;

protected:
	static void _bind_methods();
    Ref<AudioStream> get_song_stream();
    

public:
	Song() = default;
	~Song() override = default;

    // Setters
    void set_path(const String &p_path);
    void set_artist(const String &p_artist);
    void set_album(const String &p_album);
    void set_release_year(const int64_t &p_year);
    void set_raw_length(const real_t &lenght);

    // Getters
    String get_path() const {return path;}
    String get_artist() const {return artist;}
    String get_album() const {return album;}
    int64_t get_release_year() const {return release_year;}
    real_t get_raw_lenght() const {return raw_length;}
};
