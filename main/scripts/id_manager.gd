class_name IdManager
extends RefCounted

var _id_tracker_audio_file: Dictionary[String, int]

var _id_tracker_playlist: Dictionary[String, int]

## Loads all found trackers
func load_id_trackers() -> void:
	_id_tracker_audio_file = AppState.save_system.load_id_tracker_audio_file()
	_id_tracker_playlist = AppState.save_system.load_id_tracker_playlist()


## Returns the id for the given [param path] audio if exists, else makes a new unique one
func get_id_from_path(path: String) -> int:
	var id: int
	if _id_tracker_audio_file.has(path):
		id = _id_tracker_audio_file[path]
	else:
		id = _id_tracker_audio_file.size()
		_id_tracker_audio_file[path] = id
		AppState.save_system.save_id_tracker_audio_file(_id_tracker_audio_file)
	return id

## Returns the id for the [Playlist] that the given [param storage_id] belongs to
func get_id_from_playlist_storage_id(storage_id: String) -> int:
	var id: int
	if _id_tracker_playlist.has(storage_id):
		id = _id_tracker_playlist[storage_id]
	else:
		id = _id_tracker_playlist.size()
		_id_tracker_playlist[storage_id] = id
		AppState.save_system.save_id_tracker_playlist(_id_tracker_playlist)
	return id

## Removes a [Playlist] from the tracker and AppState entry and requests deletion from disk
func delete_id_from_playlist_tracker(storage_id: String) -> void:
	var id: int
	if _id_tracker_playlist.has(storage_id):
		id = _id_tracker_playlist[storage_id]
		_id_tracker_playlist.erase(storage_id)
	else:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to delete a playlist of non-existent storage_id: %s" % storage_id,
		)
		return

	AppState.playlists.erase(id)
	AppState.save_system.delete_playlist_file(storage_id)
