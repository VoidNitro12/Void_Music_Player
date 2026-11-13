class_name LibrarySettingsService
extends RefCounted
## Class dictating what the Apps library system can do, regardless of the UI

var _path_lookup: Dictionary[String, ScanFolderView]

var _library: Library
var _file_scanner: FileScanner
var _settings: Settings
var _bus: EventBus

## Whether to scan the given folder alone or recursively scan its children as we;;
var include_sub_dirs: bool = false:
	set(value):
		if include_sub_dirs != value:
			include_sub_dirs = value

			for scan: ScanFolderView in _path_lookup.values():
				scan.update_file_count(value)

func _set_up_dependencies(bus: EventBus, scanner: FileScanner, settings: Settings, library: Library) -> void:
	_bus = bus
	_file_scanner = scanner
	_settings = settings
	_library = library

func scan_folders() -> void:
	var paths: PackedStringArray

	for path: String in _path_lookup.keys():
		paths.append(path)
	
	if paths.is_empty():
		return

	_bus.data.log_error.emit(ErrorLogger.LogLevel.INFO, "Scanning folders: %s" % paths)

	
	var _scan_task_id: int = WorkerThreadPool.add_task(
			_scan.bind(paths)
	)

	_bus.ui.start_loading_wait.emit()
	
	

func _scan(paths: PackedStringArray) -> void:
	var scan_results: Array[Dictionary]
	for path: String in paths:
		var result: Array[Dictionary] = _file_scanner.scan_dir(path, include_sub_dirs)
		scan_results.append_array(result)

	_scan_done.call_deferred(scan_results)

func _scan_done(scan_results: Array[Dictionary]) -> void:
	
	for dict: Dictionary in scan_results:
		_library.create_song_from_audio_file_dict(dict)

	_bus.ui.refresh_all_tracks.emit()

	_bus.ui.refresh_albums.emit()
	
	_bus.ui.end_loading_wait.emit()

	_settings.loaded_paths = (PackedStringArray(_path_lookup.keys()))

	_bus.data.save_app_data.emit()

	_bus.data.log_error.emit(ErrorLogger.LogLevel.INFO, "Completed Scanning folders")

func add_dir_to_lookup(dir: String) -> ScanFolderView:
	if _path_lookup.has(dir):
		_bus.data.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"Attempted to add an already existing path to folder scan",
		)
		return null

	var scan: ScanFolderView = LibrarySection.SCAN_FOLDER_VIEW_SCENE.instantiate()
	scan.set_up_extra_dependencies(_file_scanner)
	scan.set_bus(_bus)
	scan.set_data(dir, include_sub_dirs)
	_path_lookup[dir] = scan
	return scan

func remove_dir(dir: String) -> void:
	if _path_lookup.has(dir):
		_path_lookup.erase(dir)

func clear_lookup() -> void:
	_path_lookup.clear()