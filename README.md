# Void-Music-Player

A music player built with the Godot game engine. Scans for local music files and enables playback, playlist creation, queue control, and more.

Supports MP3, WAV, OGG Vorbis, FLAC and M4A playback via
[MiniAudio](https://github.com/mackron/miniaudio), with M4A/AAC/ALAC
decoding via [FFmpeg](https://ffmpeg.org).

## Building

Building requires Godot 4.7.1-stable or later. After cloning the repo, update the submodules with `git submodule update --init --recursive`. \
Then run the [build script](scripts/build.sh), which will compile all dependencies and build the extensions for Godot. 
Exports can then be made via the editor.

## License

Void Music Player is MIT licensed (see [License](LICENSE)). It uses third-party
software: Godot Engine and godot-cpp (MIT), miniaudio (public domain/MIT-0),
nlohmann/json (MIT), TagLib (used under MPL-1.1), and FFmpeg (LGPL-2.1,
dynamically linked). Details in [Third_party_notices](THIRD-PARTY-NOTICES.md).
