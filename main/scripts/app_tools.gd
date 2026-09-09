class_name AppTool
extends RefCounted
## Static class for all app helpers and cross file enums

## Containers of the [FullScreenPlayer]
enum FullScreenCenterPanel {
	MAIN,
	SETTINGS,
}

## Containers of the [MainTab]
enum MainTabSections {
	NONE,
	ALL_SONGS,
	ALBUMS,
	PLAYLISTS,
}

## Options for opening [PlaylistOptionsPopup]
enum PlaylistEditType {
	CREATE,
	EDIT,
}

## Converts a given float into its equivalent time stamp in m:s (minutes and seconds)
static func float_to_timestamp(raw_length: float) -> String:
	var minutes: int = floor(raw_length / 60.0)
	var seconds: int = int(raw_length) % 60
	var song_length: String = "%02d:%02d" % [minutes, seconds]
	return song_length

## Returns a valid AudioStream derived instance for the specified extension.
## [b]NOTE:[/b] Only deals with supported formats declared in [member FileScanner.VALID_EXTENSIONS]
static func get_audio_stream(extension: String) -> AudioStream:
	var stream: AudioStream
	match extension:
		"mp3":
			stream = AudioStreamMP3.new()
		"wav":
			stream = AudioStreamWAV.new()
		"ogg":
			stream = AudioStreamOggVorbis.new()
		_:
			push_error("Unsupported audio extension \"%s\"" % extension)
			return
	return stream
