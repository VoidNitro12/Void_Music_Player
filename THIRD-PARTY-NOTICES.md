# Third-party notices

Void Music Player is licensed under the MIT License (see [License](LICENSE)). It builds
on the following third-party software. This file lists each component with
its license and source.

## Godot Engine

- Used as: application runtime
- License: MIT
- Source: https://github.com/godotengine/godot

## godot-cpp (Godot 4.3 API)

- Used as: C++ bindings for the GDExtension, compiled into the extension library
- License: MIT
- Source: https://github.com/godotengine/godot-cpp

## miniaudio 0.11.25

- Used as: audio playback engine, compiled into the extension library
- License: Public Domain or MIT-0, at the user's choice (per upstream)
- Source: https://github.com/mackron/miniaudio

## nlohmann/json 3.12.0

- Used as: JSON parsing
- License: MIT
- Source: https://github.com/nlohmann/json
- Copyright (c) 2013-2025 Niels Lohmann

## TagLib 2.3.2

- Used as: audio metadata reading, statically compiled into the extension library
- License: Dual licensed; this project uses TagLib under the Mozilla Public
  License 1.1 (MPL-1.1), which permits this form of use. TagLib's source code
  remains available upstream.
- Source: https://github.com/taglib/taglib

## FFmpeg (libavformat, libavcodec, libavutil, libswresample)

- Used as: M4A/AAC/ALAC decoding via a custom miniaudio decoding backend
- License: LGPL-2.1-or-later, used via dynamic linking only. This project
  does not statically link FFmpeg. FFmpeg's source code is available upstream.
- Source: https://ffmpeg.org