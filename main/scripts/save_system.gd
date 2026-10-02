class_name SaveSystem
extends RefCounted
## Static class for handling persistence for app related data

var _save_file_path: String
var _playlist_save_folder: String
var _id_tracker_audio_path: String
var _id_tracker_playlist_path: String


func set_save_file_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		# Making this and editor error instead of logging it cause it really should only concern
		# the editor. That and the Bootstrap should create the given paths if they dont exist
		push_error("Path \"%s\" does not exist" % path)
		return
	_save_file_path = path


func set_playlist_save_folder(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		push_error("Path \"%s\" does not exist" % path)
		return
	_playlist_save_folder = path


func set_id_tracker_audio_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Path \"%s\" does not exist" % path)
		return
	_id_tracker_audio_path = path


func set_id_tracker_playlist_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Path \"%s\" does not exist" % path)
		return
	_id_tracker_playlist_path = path


## Save all relevant user data
## TODO: Store loaded dir paths after updating settings to have an option to
func save_data() -> void:
	if not FileAccess.file_exists(_save_file_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save data, _save_file_path does not exist",
		)
		return

	var file: FileAccess = FileAccess.open(_save_file_path, FileAccess.WRITE)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open save app data for saving. Issue: %s"
			% error_string(FileAccess.get_open_error()),
		)
		return

	var save_dict: Dictionary

	save_dict["loaded_paths"] = AppState.loaded_paths
	save_dict["app_version"] = AppState.app_version

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		AppEvents.data.log_error.emit(ErrorLogger.LogLevel.ERROR, "Error while saving app data")
		return
	file.close()


## load and set all relevant user data
func load_data() -> void:
	if not FileAccess.file_exists(_save_file_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load save data, _save_file_path does not exist",
		)
		return

	var file: FileAccess = FileAccess.open(_save_file_path, FileAccess.READ)
	if file == null:
		AppEvents.data.log_error.emit(ErrorLogger.LogLevel.ERROR, "Could not open app data save")
		return

	var parsed: Dictionary
	var check: Variant = JSON.parse_string(file.get_as_text())
	if typeof(check) == TYPE_NIL:
		return
	if typeof(check) == TYPE_DICTIONARY:
		parsed = check
	else:
		return

	file.close()

	if parsed.is_empty():
		return

	parsed.get("app_version", "0.0.0")
	if parsed["app_version"] != AppState.app_version:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"save version mismatch, attempting to load",
		)

	AppState.loaded_paths = PackedStringArray(parsed.get("loaded_paths", []))


func save_playlist(playlist: Playlist) -> void:
	if not DirAccess.dir_exists_absolute(_playlist_save_folder):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist, _playlist_save_folder does not exist",
		)
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(playlist.storage_id + ".json")

	var file: FileAccess

	file = FileAccess.open(playlist_save_path, FileAccess.WRITE)

	var store_songs: PackedStringArray
	for song: Song in playlist.songs.values():
		store_songs.append(song.path)

	var save_dict: Dictionary = {
		"title": playlist.title,
		"description": playlist.description,
		"date_dict": playlist.date_dict,
		"cover_path": playlist.cover_path,
		"songs": store_songs,
	}

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist: %s" % playlist.storage_id,
		)
		return
	file.close()


func load_playlist(storage_id: String) -> void:
	if not DirAccess.dir_exists_absolute(_playlist_save_folder):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load playlist, _playlist_save_folder does not exist",
		)
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(storage_id + ".json")

	if not FileAccess.file_exists(playlist_save_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load playlist: %s" % storage_id,
		)
		return

	var file: FileAccess = FileAccess.open(playlist_save_path, FileAccess.READ)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open playlist save: %s" % storage_id,
		)
		return

	var parsed: Dictionary
	var check: Variant = JSON.parse_string(file.get_as_text())
	if typeof(check) == TYPE_NIL:
		return
	if typeof(check) == TYPE_DICTIONARY:
		parsed = check
	else:
		return
	file.close()

	if parsed.is_empty():
		return

	var playlist: Playlist = Playlist.new()
	playlist.storage_id = storage_id
	playlist.id = AppState.id_manager.get_id_from_playlist_storage_id(storage_id)
	playlist.title = parsed.get("title", "")
	playlist.description = parsed.get("description", "")
	playlist.date_dict.assign(
		parsed.get("date_dict", { "day": 0, "month": 0, "year": 0, "weekday": 0 })
	)
	playlist.cover_path = parsed.get("cover_path", "")
	var loaded_songs: PackedStringArray = parsed.get("songs", [])
	for path: String in loaded_songs:
		AppState.create_song_from_audio_file_dict(AppState.file_scanner.get_audio_dict_from_path(
				path
			))
		var song_id: int = AppState.get_id_from_path(path)
		if AppState.all_tracks.has(song_id):
			playlist.songs[song_id] = AppState.all_tracks[song_id]
	AppState.playlists[playlist.id] = playlist


func load_all_playlists() -> void:
	if not DirAccess.dir_exists_absolute(_playlist_save_folder):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load playlist, _playlist_save_folder does not exist",
		)
		return

	var all_playlists_files: PackedStringArray = DirAccess.get_files_at(_playlist_save_folder)

	for playlist_file: String in all_playlists_files:
		load_playlist(playlist_file.get_basename())

	AppEvents.ui.refresh_playlist.emit()


func delete_playlist_file(storage_id: String) -> void:
	if not DirAccess.dir_exists_absolute(_playlist_save_folder):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not delete playlist, _playlist_save_folder does not exist",
		)
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(storage_id + ".json")

	if not FileAccess.file_exists(playlist_save_path):
		return

	DirAccess.remove_absolute(playlist_save_path)


## Stores the updated _id_tracker_audio_file to disk
func save_id_tracker_audio_file(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = FileAccess.open(_id_tracker_audio_path, FileAccess.WRITE)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open audio file id tracker save",
		)
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save audio file id tracker save",
		)
		return
	file.close()


## Loads the _id_tracker_audio_file from disk
func load_id_tracker_audio_file() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	if not FileAccess.file_exists(_id_tracker_audio_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load audio id tracker, _id_tracker_audio_path does not exist",
		)
		return tracker

	var file: FileAccess = FileAccess.open(_id_tracker_audio_path, FileAccess.READ)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open audio file id tracker save",
		)
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)
	file.close()
	return tracker


func save_id_tracker_playlist(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = FileAccess.open(_id_tracker_playlist_path, FileAccess.WRITE)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open playlist id tracker save",
		)
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist id tracker save",
		)
		return
	file.close()


func load_id_tracker_playlist() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	if not FileAccess.file_exists(_id_tracker_playlist_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load playlist id tracker, _id_tracker_playlist_path does not exist",
		)
		return tracker

	var file: FileAccess = FileAccess.open(_id_tracker_playlist_path, FileAccess.READ)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open playlist id tracker save",
		)
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)
	file.close()
	return tracker
