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
	
	var error_logger: ErrorLogger = ErrorLogger.new()
	AppState.error_logger = error_logger
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
	
	var event_bus: EventBus = EventBus.new()
	event_bus.set_up()
	AppState.event_bus = event_bus

	var save_system: SaveSystem = SaveSystem.new()
	save_system.set_bus(event_bus)
	save_system.set_save_file_path(AppTool.SAVE_FILE_PATH)
	save_system.set_playlist_save_folder(AppTool.PLAYLIST_SAVE_FOLDER)
	save_system.set_id_tracker_audio_path(AppTool.ID_TRACKER_AUDIO_FILE_PATH)
	save_system.set_id_tracker_playlist_path(AppTool.ID_TRACKER_PLAYLIST_PATH)
	AppState.save_system = save_system
	
	var id_manager: IdManager = IdManager.new()
	id_manager.set_bus(event_bus)
	AppState.id_manager = id_manager
	
	AppState.settings = Settings.new()
	
	var stats: Stats = Stats.new()
	stats.set_bus(event_bus)
	AppState.stats = stats
	
	AppState.theme_manager = ThemeManager.new()
	AppState.theme_manager.set_up()

	var audio_handler: AudioHandler = AudioHandler.new()
	audio_handler.set_up(event_bus, error_logger)
	AppState.add_child(audio_handler)
	audio_handler.context.set_queue_sources(
		AppState.all_tracks,
		AppState.albums,
		AppState.playlists,
	)
	AppState.audio_handler = audio_handler

	event_bus.data.save_app_data.connect(AppState.save_system.save_data)
	
	event_bus.data.save_playlist.connect(AppState.save_system.save_playlist)
	
	event_bus.data.delete_playlist.connect(AppState.id_manager.delete_id_from_playlist_tracker)
	
	event_bus.data.log_error.connect(AppState.error_logger.log_error)
	
	event_bus.audio.song_played.connect(AppState.stats.add_to_songs_played)
	
	event_bus.ui.change_app_accent_colour.connect(AppState.theme_manager.change_accent)
	
	event_bus.ui.change_accent_darken_amount.connect(func (value: float)-> void: 
		AppState.theme_manager.set_accent_darken_ratio(value))
	
	event_bus.ui.change_accent_lighten_amount.connect(func(value: float)->void: 
		AppState.theme_manager.set_accent_lighten_ratio(value))
	
	event_bus.ui.set_accent_ratio_no_signal.connect(func(lighten: float, darken: float)->void:
		AppState.theme_manager.set_accent_lighten_ratio(lighten, false)
		AppState.theme_manager.set_accent_darken_ratio(darken, false)
		)

	await event_bus.ui.ui_ready
	
	AppState.id_manager.load_id_trackers()
	AppState.save_system.load_data()
	AppState.save_system.load_all_playlists()
	
	event_bus.data.rescan_loaded_paths.emit()
	
	event_bus.ui.refresh_all_tracks.emit()
	event_bus.ui.refresh_all_playlists.emit()
	event_bus.ui.refresh_albums.emit()
	event_bus.ui.updated_recently_played.emit(AppState.stats.songs_played)

static func shut_down()-> void: 
	AppState.save_system.save_data()
	AppState.get_tree().quit()
