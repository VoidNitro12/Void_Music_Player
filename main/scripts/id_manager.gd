class_name IdManager
extends RefCounted

var _id_tracker_playlist: Dictionary[String, int]

var _bus: EventBus

var _save_system: SaveSystem

var _library:Library

var _meta_data_cache_path: String

func set_dependencies(bus: EventBus, save_system: SaveSystem, library: Library, meta_data_cache_path: String)-> void: 
	_bus = bus
	_save_system = save_system
	_library = library
	_meta_data_cache_path = meta_data_cache_path

## Loads all found trackers
func load_id_trackers() -> void:
	_id_tracker_playlist = _save_system.load_id_tracker_playlist()

## Retrieves the path of the song associated with this uuid, returning an empty string upon failure
func get_path_from_song_uuid(uuid: String) -> String:
	var path: String = ""
	var file: FileAccess = FileAccess.open(_meta_data_cache_path, FileAccess.READ)
	if file == null:
		_bus.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Could not get path for uuid: %s" % uuid + ". Issue: %s" % FileAccess.get_open_error(),
				)
		return path
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	var uuids: Dictionary = parsed.get("uuids", {})
	if uuids.is_empty():
		return path
	
	var song_data: Dictionary = parsed.get(uuid, {})
	if song_data.is_empty():
		return path
	
	path = song_data.get("path", "")
	return path


## Removes a [Playlist] from the tracker 
func delete_id_from_playlist_tracker(playlist: Playlist) -> void:
	var uuid: String = playlist.uuid
	if _id_tracker_playlist.has(uuid):
		_id_tracker_playlist.erase(uuid)
		_save_system.save_id_tracker_playlist(_id_tracker_playlist)
	else:
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to delete a playlist of non-existent uuid: %s" % uuid,
		)
		return
