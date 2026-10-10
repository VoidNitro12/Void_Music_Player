class_name Bootstrap
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

	# Setup AppState
	AppState.app_version = ProjectSettings.get_setting("application/config/version")

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

	AppState.file_scanner = FileScanner.new()
	AppState.file_scanner.set_error_logger(AppState.error_logger)

	var save_system: SaveSystem = SaveSystem.new()
	save_system.set_save_file_path(AppTool.SAVE_FILE_PATH)
	save_system.set_playlist_save_folder(AppTool.PLAYLIST_SAVE_FOLDER)
	save_system.set_id_tracker_audio_path(AppTool.ID_TRACKER_AUDIO_FILE_PATH)
	save_system.set_id_tracker_playlist_path(AppTool.ID_TRACKER_PLAYLIST_PATH)
	AppState.save_system = save_system

	AppState.id_manager = IdManager.new()
	
	AppState.settings = Settings.new()
	
	AppState.stats = Stats.new()

	var audio_handler: AudioHandler = AudioHandler.new()
	AppState.add_child(audio_handler)
	audio_handler.context.set_queue_sources(
		AppState.all_tracks,
		AppState.albums,
		AppState.playlists,
	)
	AppState.audio_handler = audio_handler

	AppEvents.data.save_app_data.connect(AppState.save_system.save_data)
	AppEvents.data.save_playlist.connect(AppState.save_system.save_playlist)
	AppEvents.data.delete_playlist.connect(AppState.id_manager.delete_id_from_playlist_tracker)
	AppEvents.data.log_error.connect(AppState.error_logger.log_error)
	AppEvents.audio.song_played.connect(AppState.stats.add_to_songs_played)

	AppState.id_manager.load_id_trackers()
	AppState.save_system.load_data()
	AppState.save_system.load_all_playlists()
