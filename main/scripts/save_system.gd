class_name SaveSystem
extends RefCounted
## Static class for handling persistence for app related data


## Save all relevant user data
## TODO: Store loaded dir paths after updating settings to have an option to
static func save_data() -> void:
	if not FileAccess.file_exists(AppTool.SAVE_FILE_PATH):
		return

	var file: FileAccess = FileAccess.open(AppTool.SAVE_FILE_PATH, FileAccess.READ_WRITE)
	if file == null:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open save app data for saving. Issue: %s"
			% error_string(FileAccess.get_open_error()),
		)
		return

	#load the current save if exists
	var save_dict: Dictionary
	#var check: Variant = JSON.parse_string(file.get_as_text())
	#if typeof(check) == TYPE_NIL:
	#return
	#if typeof(check) == TYPE_DICTIONARY:
	#save_dict = check
	#else:
	#return
	save_dict["loaded_paths"] = AppState.loaded_paths
	save_dict["app_version"] = AppState.app_version

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		AppEvents.log_error.emit(ErrorLogger.LogLevel.ERROR, "Error while saving app data")
		return
	file.close()


## load and set all relevant user data
static func load_data() -> void:
	if not FileAccess.file_exists(AppTool.SAVE_FILE_PATH):
		return

	var file: FileAccess = FileAccess.open(AppTool.SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		AppEvents.log_error.emit(ErrorLogger.LogLevel.ERROR, "Could not open app data save")
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
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"save version mismatch, attempting to load",
		)

	AppState.loaded_paths = PackedStringArray(parsed.get("loaded_paths", []))



static func save_playlist(playlist: Playlist) -> void:
	if not DirAccess.dir_exists_absolute(AppTool.PLAYLIST_SAVE_FOLDER):
		return

	var playlist_save_path: String = AppTool.PLAYLIST_SAVE_FOLDER.path_join(
		playlist.storage_id + ".json"
	)

	var file: FileAccess
	if not FileAccess.file_exists(playlist_save_path):
		file = FileAccess.open(playlist_save_path, FileAccess.WRITE)
	else:
		file = FileAccess.open(playlist_save_path, FileAccess.READ_WRITE)

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
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist: %s" % playlist.storage_id,
		)
		return
	file.close()


static func load_playlist(storage_id: String) -> void:
	if not DirAccess.dir_exists_absolute(AppTool.PLAYLIST_SAVE_FOLDER):
		return

	var playlist_save_path: String = AppTool.PLAYLIST_SAVE_FOLDER.path_join(storage_id + ".json")

	if not FileAccess.file_exists(playlist_save_path):
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not load playlist: %s" % storage_id,
		)
		return

	var file: FileAccess = FileAccess.open(playlist_save_path, FileAccess.READ)
	if file == null:
		AppEvents.log_error.emit(
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
	playlist.id = AppState.get_id_from_playlist_storage_id(storage_id)
	playlist.title = parsed.get("title", "")
	playlist.description = parsed.get("description", "")
	playlist.date_dict.assign(
		parsed.get("date_dict", { "day": 0, "month": 0, "year": 0, "weekday": 0 })
	)
	playlist.cover_path = parsed.get("cover_path", "")
	var loaded_songs: PackedStringArray = parsed.get("songs", [])
	for path: String in loaded_songs:
		AppTool.create_song_from_audio_file_dict(AppState.file_scanner.get_audio_dict_from_path(
				path
			))
		var song_id: int = AppState.get_id_from_path(path)
		if AppState.all_tracks.has(song_id):
			playlist.songs[song_id] = AppState.all_tracks[song_id]
	AppState.playlists[playlist.id] = playlist


static func load_all_playlists() -> void:
	if not DirAccess.dir_exists_absolute(AppTool.PLAYLIST_SAVE_FOLDER):
		return

	var all_playlists_files: PackedStringArray = DirAccess.get_files_at(
		AppTool.PLAYLIST_SAVE_FOLDER
	)

	for playlist_file: String in all_playlists_files:
		load_playlist(playlist_file.get_basename())

	AppEvents.refresh_playlist.emit()

static func delete_playlist_file(storage_id: String) -> void:
	if not DirAccess.dir_exists_absolute(AppTool.PLAYLIST_SAVE_FOLDER):
		return

	var playlist_save_path: String = AppTool.PLAYLIST_SAVE_FOLDER.path_join(storage_id + ".json")

	if not FileAccess.file_exists(playlist_save_path):
		return
	
	DirAccess.remove_absolute(playlist_save_path)

## Stores the updated _id_tracker_audio_file to disk
static func save_id_tracker_audio_file(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = FileAccess.open(AppTool.ID_TRACKER_AUDIO_FILE_PATH, FileAccess.WRITE)
	if file == null:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open audio file id tracker save",
		)
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save audio file id tracker save",
		)
		return
	file.close()


## Loads the _id_tracker_audio_file from disk
static func load_id_tracker_audio_file() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	if not FileAccess.file_exists(AppTool.ID_TRACKER_AUDIO_FILE_PATH):
		return tracker

	var file: FileAccess = FileAccess.open(AppTool.ID_TRACKER_AUDIO_FILE_PATH, FileAccess.READ)
	if file == null:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open audio file id tracker save",
		)
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)
	file.close()
	return tracker


static func save_id_tracker_playlist(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = FileAccess.open(AppTool.ID_TRACKER_PLAYLIST_PATH, FileAccess.WRITE)
	if file == null:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open playlist id tracker save",
		)
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not save playlist id tracker save",
		)
		return
	file.close()


static func load_id_tracker_playlist() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	if not FileAccess.file_exists(AppTool.ID_TRACKER_PLAYLIST_PATH):
		return tracker

	var file: FileAccess = FileAccess.open(AppTool.ID_TRACKER_PLAYLIST_PATH, FileAccess.READ)
	if file == null:
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not open playlist id tracker save",
		)
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)
	file.close()
	return tracker
