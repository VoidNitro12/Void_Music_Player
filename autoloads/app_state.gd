extends Node
## Autoload class to store references to data used across the system

## All songs currently processed by the app
var all_tracks: Dictionary[int, Song]

## All playlist currently in the app
var playlists: Dictionary[int, Playlist]

## All albums currently in the app
var albums: Dictionary[int, Album]

## All currently loaded directories
var loaded_paths: PackedStringArray

var app_version: String

var error_logger: ErrorLogger

var file_scanner: FileScanner

var save_system: SaveSystem

## Purely for aesthetics to prevent multiple same name playlists as playlists use an id system.
## The bool is a dummy value i just need a set
var playlist_names: Dictionary[String, bool]

var session_id: String

# Holds a unique id for every audio file path given
var _id_tracker_audio_file: Dictionary[String, int]

var _id_tracker_playlist: Dictionary[String, int]


func _ready() -> void:
	AppBootstrap.start_up()


## Returns the id for the given [param path] audio if exists, else makes a new unique one
func get_id_from_path(path: String) -> int:
	var id: int
	if _id_tracker_audio_file.has(path):
		id = _id_tracker_audio_file[path]
	else:
		id = _id_tracker_audio_file.size()
		_id_tracker_audio_file[path] = id
		save_system.save_id_tracker_audio_file(_id_tracker_audio_file)
	return id


func get_id_from_playlist_storage_id(storage_id: String) -> int:
	var id: int
	if _id_tracker_playlist.has(storage_id):
		id = _id_tracker_playlist[storage_id]
	else:
		id = _id_tracker_playlist.size()
		_id_tracker_playlist[storage_id] = id
		save_system.save_id_tracker_playlist(_id_tracker_playlist)
	return id


func delete_id_from_playlist_tracker(storage_id: String) -> void:
	var id: int
	if _id_tracker_playlist.has(storage_id):
		id = _id_tracker_playlist[storage_id]
		_id_tracker_playlist.erase(storage_id)
	else:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to delete a playlist of nonexistent storage_id: %s" % storage_id,
		)
		return
	
	AppState.playlists.erase(id)
	save_system.delete_playlist_file(storage_id)
