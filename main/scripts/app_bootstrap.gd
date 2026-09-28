class_name AppBootstrap
extends RefCounted

static func start_up() -> void: 
	var session_stamp: Dictionary[String, int]
	session_stamp.assign(Time.get_date_dict_from_system(true))
	AppState.session_id = "%s%d_%d_%d-%d" % [
		AppTool.LOG_FILE_PREFIX,
		session_stamp.year,
		session_stamp.month,
		session_stamp.day,
		randi(),
	]

	AppState.error_logger = ErrorLogger.new()
	AppState.error_logger.set_session_id(AppState.session_id)

	AppState.error_logger.log_error(ErrorLogger.LogLevel.INFO, "Started Application")

	AppState.error_logger.log_error(ErrorLogger.LogLevel.INFO, "Checking Required Folders")
	var ensured_folders: PackedStringArray = [
		AppTool.SAVE_FOLDER,
		AppTool.PLAYLIST_COVER_CACHE,
		AppTool.PLAYLIST_SAVE_FOLDER,
		ErrorLogger.get_error_logs_path(),
		FileScanner.get_song_cover_path(),
	]
	for folder_path: String in ensured_folders:
		if not DirAccess.dir_exists_absolute(folder_path):
			AppState.error_logger.log_error(
				ErrorLogger.LogLevel.INFO,
				"Creating Required Folder: %s" % folder_path,
			)
			DirAccess.make_dir_recursive_absolute(folder_path)

	AppState.error_logger.log_error(ErrorLogger.LogLevel.INFO, "Checking Required Files")
	var ensured_files: PackedStringArray = [
		AppTool.SAVE_FILE_PATH,
		AppTool.ID_TRACKER_AUDIO_FILE_PATH,
		AppTool.ID_TRACKER_PLAYLIST_PATH,
		FileScanner.get_meta_data_cache_path(),
	]
	for file_path: String in ensured_files:
		if not FileAccess.file_exists(file_path):
			AppState.error_logger.log_error(
				ErrorLogger.LogLevel.INFO,
				"Creating Required File: %s" % file_path,
			)
			var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
			file.store_string(JSON.stringify({ }, "\t"))
			file.close()

	AppState.app_version = ProjectSettings.get_setting("application/config/version")

	AppState._id_tracker_audio_file = SaveSystem.load_id_tracker_audio_file()
	AppState._id_tracker_playlist = SaveSystem.load_id_tracker_playlist()

	AppState.file_scanner = FileScanner.new()
	AppState.file_scanner.set_error_logger(AppState.error_logger)

	AppEvents.save_app_data.connect(SaveSystem.save_data)
	AppEvents.save_playlist.connect(SaveSystem.save_playlist)
	AppEvents.delete_playlist.connect(AppState.delete_id_from_playlist_tracker)
	AppEvents.log_error.connect(AppState.error_logger.log_error)
	
	SaveSystem.load_data()
	SaveSystem.load_all_playlists()
