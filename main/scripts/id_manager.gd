class_name IdManager
extends RefCounted

var _id_tracker_audio_file: Dictionary[String, int]

var _id_tracker_playlist: Dictionary[String, int]

var _id_tracker_album: Dictionary[String, int]

var _bus: EventBus

var _save_system: SaveSystem

var _library:Library

func set_dependencies(bus: EventBus, save_system: SaveSystem, library: Library)-> void: 
	_bus = bus
	_save_system = save_system
	_library = library

## Loads all found trackers
func load_id_trackers() -> void:
	_id_tracker_audio_file = _save_system.load_id_tracker_audio_file()
	_id_tracker_playlist = _save_system.load_id_tracker_playlist()


## Returns the id for the given [param path] audio if exists, else makes a new unique one
func get_id_from_path(path: String) -> int:
	var id: int
	if _id_tracker_audio_file.has(path):
		id = _id_tracker_audio_file[path]
	else:
		id = _id_tracker_audio_file.size()
		_id_tracker_audio_file[path] = id
		_save_system.save_id_tracker_audio_file(_id_tracker_audio_file)
	return id

## Returns the id for the [Playlist] that the given [param storage_id] belongs to
func get_id_from_playlist_storage_id(storage_id: String) -> int:
	var id: int
	if _id_tracker_playlist.has(storage_id):
		id = _id_tracker_playlist[storage_id]
	else:
		id = _id_tracker_playlist.size()
		_id_tracker_playlist[storage_id] = id
		_save_system.save_id_tracker_playlist(_id_tracker_playlist)
	return id

## Removes a [Playlist] from the tracker 
func delete_id_from_playlist_tracker(playlist: Playlist) -> void:
	var storage_id: String = playlist.storage_id
	if _id_tracker_playlist.has(storage_id):
		_id_tracker_playlist.erase(storage_id)
		_save_system.save_id_tracker_playlist(_id_tracker_playlist)
	else:
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to delete a playlist of non-existent storage_id: %s" % storage_id,
		)
		return

## Returns the id for the given [album_title] audio if exists, else makes a new unique one
# Not saving albums, they should be recomputed on every scan
func get_id_for_album(album_title: String) -> int:
	var id: int
	if _id_tracker_album.has(album_title):
		id = _id_tracker_album[album_title]
	else:
		id = _id_tracker_album.size()
		_id_tracker_album[album_title] = id
		
	return id