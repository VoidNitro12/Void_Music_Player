class_name AppTool
extends RefCounted
## Static class for all app helpers and cross file enums

enum AppThemes {
	DARK,
	LIGHT,
}

## Containers of the [FullScreenPlayer]
enum FullScreenCenterPanel {
	MAIN,
	SETTINGS,
}

## Containers of the [MainTab]
enum MainTabSections {
	ALL_SONGS = 0,
	ALBUMS = 1,
	PLAYLISTS = 2,
	PACK = 3,
}

## Options for opening [PlaylistOptionsPopup]
enum PlaylistEditType {
	CREATE,
	EDIT,
}

## Prefix all log file names will start with. see [ErrorLogger]
const LOG_FILE_PREFIX: String = "session_"

## Path to the general save folder of the app
const SAVE_FOLDER: String = "user://app_data/"

## Path to the specific general use save json
const SAVE_FILE_PATH: String = "user://app_data/app_data.json"

## Path to the json used for tracking song ids
const ID_TRACKER_AUDIO_FILE_PATH: String = "user://app_data/id_tracker_audio_file.json"

const ID_TRACKER_PLAYLIST_PATH: String = "user://app_data/id_tracker_playlist.json"

const PLAYLIST_SAVE_FOLDER: String = "user://app_data/playlists"

## Path to the folder containing cover images for all created playlists
const PLAYLIST_COVER_CACHE: String = "user://app_data/playlist_images/"

## Converts a given float into its equivalent time stamp in m:s (minutes and seconds)
## [b]TODO:[\b] Add hour handling
static func int_to_timestamp(raw_length: int) -> String:
	var minutes: int = floor(float(raw_length) / 60)
	var seconds: int = int(raw_length) % 60
	var song_length: String = "%02d:%02d" % [minutes, seconds]
	return song_length

## Returns a valid AudioStream derived instance for the specified extension.
## [b]NOTE:[/b] Only deals with supported formats declared in [member FileScanner.VALID_EXTENSIONS]
static func get_audio_stream(extension: String) -> AudioStream:
	var stream: AudioStream
	match extension.to_lower():
		"mp3":
			stream = AudioStreamMP3.new()
		"wav":
			stream = AudioStreamWAV.new()
		"ogg":
			stream = AudioStreamOggVorbis.new()
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"Attempted to parse unsupported audio extension \"%s\"" % extension,
			)
			return
	return stream
