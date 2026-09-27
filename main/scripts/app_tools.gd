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
			AppEvents.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"Attempted to parse unsupported audio extension \"%s\"" % extension,
			)
			return
	return stream

## Creates a brand new [Song] Resource from the given [param dict] data (Meant to be gotten from 
## the MusicPlayerLib extension).[br]
## Assigns an id if the song does not already exist else returns the existing resource
static func create_song_from_audio_file_dict(dict: Dictionary) -> void: 
	var path: String = dict.get("path", "")
	
	var id: int = AppState.get_id_from_path(path)
	if AppState.all_tracks.has(id):
		return 
	
	var song: Song = Song.new()
	song.id = id
	song.path = path
	song.cover_path = dict.get("cover_path", "")
	song.title = dict.get("title", "")
	song.artist = dict.get("artist", "")
	song.album = dict.get("album", "")
	song.release_year = dict.get("release_year", 0)
	song.raw_length = dict.get("raw_length", 0)
	AppState.all_tracks[id] = song
	
