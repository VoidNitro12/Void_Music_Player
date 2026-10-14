class_name SaveSystem
extends RefCounted
## Static class for handling persistence for app related data

var _save_file_path: String
var _playlist_save_folder: String
var _id_tracker_audio_path: String
var _id_tracker_playlist_path: String


func set_save_file_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		# Making this an editor error instead of logging it cause it really should only concern
		# the editor. That and the Bootstrap should create the given paths if they don't exist
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
func save_data() -> void:
	var path_check: bool = _check_path_exists(
		_save_file_path,
		"Could not save data, _save_file_path does not exist",
	)
	if not path_check:
		return

	var file: FileAccess = _open_save(
		_save_file_path,
		FileAccess.WRITE,
		"Could not open save app data for saving",
	)
	if file == null:
		return

	var save_dict: Dictionary

	save_dict["app_version"] = AppState.app_version
	save_dict["loaded_paths"] = AppState.settings.loaded_paths
	save_dict["scan_subdirs"] = AppState.settings.scan_subdirs
	var songs_played_save: PackedStringArray
	for song: Song in AppState.stats.songs_played:
		songs_played_save.append(song.path)
	save_dict["recently_played_songs"] = songs_played_save
	save_dict["accent_colour"] = AppState.theme_manager.current_accent

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		AppEvents.data.log_error.emit(ErrorLogger.LogLevel.ERROR, "Error while saving app data")
		return


## load and set all relevant user data
func load_data() -> void:
	var path_check: bool = _check_path_exists(
		_save_file_path,
		"Could not load save data, _save_file_path does not exist",
	)
	if not path_check:
		return

	var file: FileAccess = _open_save(
		_save_file_path,
		FileAccess.READ,
		"Could not open app data save",
	)
	if file == null:
		return

	var parsed: Dictionary
	var check: Variant = JSON.parse_string(file.get_as_text())
	if typeof(check) == TYPE_NIL:
		return
	if typeof(check) == TYPE_DICTIONARY:
		parsed = check
	else:
		return

	if parsed.is_empty():
		return

	parsed.get("app_version", "0.0.0")
	# TODO proper versioning
	if parsed["app_version"] != AppState.app_version:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"save version mismatch, attempting to load",
		)

	AppState.settings.loaded_paths = PackedStringArray(parsed.get("loaded_paths", []))
	AppState.settings.scan_subdirs = parsed.get("scan_subdirs", false)
	var recent_song_paths: PackedStringArray = parsed.get("recently_played_songs", [])
	var recent_songs: Array[Song]
	for path: String in recent_song_paths:
		AppState.create_song_from_audio_file_dict(AppState.file_scanner.get_audio_dict_from_path(
				path
			))
		var song_id: int = AppState.id_manager.get_id_from_path(path)
		if AppState.all_tracks.has(song_id):
			recent_songs.append(AppState.all_tracks[song_id])
	AppState.stats.songs_played = recent_songs
	AppEvents.ui.change_app_accent_colour.emit(
		parsed.get("accent_colour", ThemeManager.Accents.GREEN)
	)


func save_playlist(playlist: Playlist) -> void:
	var dir_exists: bool = _check_path_exists(
		_playlist_save_folder,
		"Could not save playlist, _playlist_save_folder does not exist",
		true,
	)
	if not dir_exists:
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(playlist.storage_id + ".json")

	var file: FileAccess = _open_save(
		playlist_save_path,
		FileAccess.WRITE,
		"Could not save playlist file to disk",
	)
	if file == null:
		return

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


func load_playlist(storage_id: String) -> void:
	var dir_exists: bool = _check_path_exists(
		_playlist_save_folder,
		"Could not load playlist, _playlist_save_folder does not exist",
		true,
	)
	if not dir_exists:
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(storage_id + ".json")

	var path_exists: bool = _check_path_exists(
		playlist_save_path,
		"Could not load playlist: %s" % storage_id,
	)
	if not path_exists:
		return

	var file: FileAccess = _open_save(
		playlist_save_path,
		FileAccess.READ,
		"Could not open playlist save: %s" % storage_id,
	)
	if file == null:
		return

	var parsed: Dictionary
	var check: Variant = JSON.parse_string(file.get_as_text())
	if typeof(check) == TYPE_NIL:
		return
	if typeof(check) == TYPE_DICTIONARY:
		parsed = check
	else:
		return

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
		var song_id: int = AppState.id_manager.get_id_from_path(path)
		if AppState.all_tracks.has(song_id):
			playlist.songs[song_id] = AppState.all_tracks[song_id]
	AppState.playlists[playlist.id] = playlist


func load_all_playlists() -> void:
	var dir_exists: bool = _check_path_exists(
		_playlist_save_folder,
		"Could not load playlist, _playlist_save_folder does not exist",
		true,
	)
	if not dir_exists:
		return

	var all_playlists_files: PackedStringArray = DirAccess.get_files_at(_playlist_save_folder)

	for playlist_file: String in all_playlists_files:
		load_playlist(playlist_file.get_basename())

	AppEvents.ui.refresh_all_playlists.emit()


func delete_playlist_file(storage_id: String) -> void:
	var dir_exists: bool = _check_path_exists(
		_playlist_save_folder,
		"Could not delete playlist, _playlist_save_folder does not exist",
		true,
	)
	if not dir_exists:
		return

	var playlist_save_path: String = _playlist_save_folder.path_join(storage_id + ".json")

	if not FileAccess.file_exists(playlist_save_path):
		return

	DirAccess.remove_absolute(playlist_save_path)


## Stores the updated _id_tracker_audio_file to disk
func save_id_tracker_audio_file(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = _open_save(
		_id_tracker_audio_path,
		FileAccess.WRITE,
		"Could not open audio file id tracker save",
	)
	if file == null:
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save audio file id tracker save",
		)
		return


## Loads the _id_tracker_audio_file from disk
func load_id_tracker_audio_file() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	var path_exists: bool = _check_path_exists(
		_id_tracker_audio_path,
		"Could not load audio id tracker, _id_tracker_audio_path does not exist",
	)
	if not path_exists:
		return tracker

	var file: FileAccess = _open_save(
		_id_tracker_audio_path,
		FileAccess.READ,
		"Could not open audio file id tracker save",
	)
	if file == null:
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)

	return tracker


func save_id_tracker_playlist(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = _open_save(
		_id_tracker_playlist_path,
		FileAccess.WRITE,
		"Could not open playlist id tracker save",
	)
	if file == null:
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist id tracker save",
		)
		return


func load_id_tracker_playlist() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	var path_exists: bool = _check_path_exists(
		_id_tracker_playlist_path,
		"Could not load playlist id tracker, _id_tracker_playlist_path does not exist",
	)
	if not path_exists:
		return tracker

	var file: FileAccess = _open_save(
		_id_tracker_playlist_path,
		FileAccess.READ,
		"Could not open playlist id tracker save",
	)
	if file == null:
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)

	return tracker


func _open_save(path: String, flag: FileAccess.ModeFlags, err_msg: String) -> FileAccess:
	var file: FileAccess = FileAccess.open(path, flag)
	if file == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			err_msg + ". Issue: %s" % FileAccess.get_open_error(),
		)
		return null

	return file


func _check_path_exists(path: String, err_msg: String, is_dir: bool = false) -> bool:
	if is_dir:
		if not DirAccess.dir_exists_absolute(path):
			AppEvents.data.log_error.emit(ErrorLogger.LogLevel.ERROR, err_msg)
			return false
	else:
		if not FileAccess.file_exists(path):
			AppEvents.data.log_error.emit(ErrorLogger.LogLevel.ERROR, err_msg)
			return false

	return true
