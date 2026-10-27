class_name SaveSystem
extends RefCounted
## Static class for handling persistence for app related data

var _save_file_path: String
var _playlist_save_folder: String
var _id_tracker_audio_path: String
var _id_tracker_playlist_path: String
var _bus: EventBus
var _library: Library
var _stats: Stats
var _settings: Settings
var _theme_manager: ThemeManager
var _scanner: FileScanner

# Items are set to null by default cause of isolated testing where you wouldnt need every dependacy
## Sets up the event bus this object will use for any cross system operations
func set_dependacies(
	bus: EventBus = null,
	library: Library = null,
	stats: Stats = null,
	settings: Settings = null,
	theme_manager: ThemeManager = null,
	file_scanner: FileScanner = null,
) -> void:
	_bus = bus
	_library = library
	_stats = stats
	_settings = settings
	_theme_manager = theme_manager
	_scanner = file_scanner


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
	save_dict["loaded_paths"] = _settings.loaded_paths
	save_dict["scan_subdirs"] = _settings.scan_subdirs
	var songs_played_save: PackedStringArray
	for song: Song in _stats.songs_played:
		songs_played_save.append(song.path)
	save_dict["recently_played_songs"] = songs_played_save
	save_dict["accent_colour"] = _theme_manager.current_accent
	var accent_ratios: PackedFloat64Array = _theme_manager.get_accent_ratios()
	save_dict["accent_lighten_ratio"] = accent_ratios[0]
	save_dict["accent_darken_ratio"] = accent_ratios[1]

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		_bus.data.log_error.emit(ErrorLogger.LogLevel.ERROR, "Error while saving app data")
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

	var app_version: String = parsed.get("app_version", "0.0.0")
	# TODO proper versioning
	if app_version != AppState.app_version:
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"save version mismatch, attempting to load",
		)

	_settings.loaded_paths = PackedStringArray(parsed.get("loaded_paths", []))
	_settings.scan_subdirs = parsed.get("scan_subdirs", false)
	var recent_song_paths: PackedStringArray = parsed.get("recently_played_songs", [])
	var recent_songs: Array[Song]
	for path: String in recent_song_paths:
		_library.create_song_from_audio_file_dict(_scanner.get_audio_dict_from_path(path))
		var song_id: int = AppState.id_manager.get_id_from_path(path)
		if _library.song_exists(song_id):
			recent_songs.append(_library.get_song_from_all_tracks(song_id))

	_stats.songs_played = recent_songs

	_bus.ui.change_app_accent_colour.emit(parsed.get("accent_colour", ThemeManager.Accents.GREEN))

	_bus.ui.set_accent_ratio_no_signal.emit(
		parsed.get("accent_lighten_ratio", 0.2),
		parsed.get("accent_darken_ratio", 0.2),
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
		_bus.data.log_error.emit(
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

	_library.add_playlist(playlist)

	var loaded_songs: PackedStringArray = parsed.get("songs", [])
	for path: String in loaded_songs:
		_library.create_song_from_audio_file_dict(_scanner.get_audio_dict_from_path(path))
		var song_id: int = AppState.id_manager.get_id_from_path(path)
		if _library.song_exists(song_id):
			_library.add_song_to_entry(
				_library.get_song_from_all_tracks(song_id),
				AppTool.ContextType.PLAYLIST,
				playlist.id,
			)


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

	_bus.ui.refresh_all_playlists.emit()


func delete_playlist_file(playlist_id: int) -> void:
	var dir_exists: bool = _check_path_exists(
		_playlist_save_folder,
		"Could not delete playlist, _playlist_save_folder does not exist",
		true,
	)
	if not dir_exists:
		return
	
	var playlist: Playlist = _library.get_playlist(playlist_id)
	
	if playlist == null: 
		return
	
	var playlist_save_path: String = _playlist_save_folder.path_join(playlist.storage_id + ".json")

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
		_bus.data.log_error.emit(
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
		_bus.data.log_error.emit(
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
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			err_msg + ". Issue: %s" % FileAccess.get_open_error(),
		)
		return null

	return file


func _check_path_exists(path: String, err_msg: String, is_dir: bool = false) -> bool:
	if is_dir:
		if not DirAccess.dir_exists_absolute(path):
			_bus.data.log_error.emit(ErrorLogger.LogLevel.ERROR, err_msg)
			return false
	else:
		if not FileAccess.file_exists(path):
			_bus.data.log_error.emit(ErrorLogger.LogLevel.ERROR, err_msg)
			return false

	return true
