class_name SettingsLibrarySection
extends Panel
## Handles UI for selecting and scanning folders for audio files

const SCAN_FOLDER_VIEW_SCENE: PackedScene = preload(
	"res://main/ui/scenes/settings_tab/library_section/ScanFolderView.tscn"
)

@export var folders_container: VBoxContainer
@export var add_folder_btn: Button
@export var scan_folders_btn: Button
@export var file_dialog: FileDialog

@export_group("Scan Options")
@export var include_subdirs_btn: CheckButton

var path_lookup: Dictionary[String, ScanFolderView]


func _ready() -> void:
	add_folder_btn.pressed.connect(_get_folder)
	scan_folders_btn.pressed.connect(scan_folders)

	AppEvents.data.rescan_loaded_paths.connect(_re_scan)


## Scans all the selected folder's for audio, updates AppState and signals for a ui refresh
func scan_folders() -> void:
	var paths: PackedStringArray

	for path: String in path_lookup.keys():
		paths.append(path)

	AppEvents.data.log_error.emit(ErrorLogger.LogLevel.INFO, "Scanning folders: %s" % paths)
	var _scan_task_id: int = WorkerThreadPool.add_task(
		_scan.bind(paths, include_subdirs_btn.button_pressed)
	)
	AppEvents.ui.start_loading_wait.emit()


func _scan(paths: PackedStringArray, check_subdirs: bool) -> void:
	var scan_results: Array[Dictionary]
	for path: String in paths:
		var result: Array[Dictionary] = AppState.file_scanner.scan_dir(path, check_subdirs)
		scan_results.append_array(result)

	call_deferred("_scan_done", scan_results)


func _scan_done(scan_results: Array[Dictionary]) -> void:
	for dict: Dictionary in scan_results:
		AppState.create_song_from_audio_file_dict(dict)

	AppEvents.ui.refresh_all_tracks.emit()

	AppEvents.ui.refresh_albums.emit()

	AppEvents.ui.end_loading_wait.emit()

	AppState.loaded_paths = (PackedStringArray(path_lookup.keys()))

	AppEvents.data.save_app_data.emit()

	AppEvents.data.log_error.emit(ErrorLogger.LogLevel.INFO, "Completed Scanning folders")


func _get_folder() -> void:
	file_dialog.visible = true
	if file_dialog.dir_selected.is_connected(_add_scan_view):
		file_dialog.dir_selected.disconnect(_add_scan_view)
	file_dialog.dir_selected.connect(_add_scan_view, Object.ConnectFlags.CONNECT_ONE_SHOT)


func _add_scan_view(dir: String) -> void:
	if path_lookup.has(dir):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Attempted to add an already existing path to folder scan",
		)
		return

	var scan: ScanFolderView = SCAN_FOLDER_VIEW_SCENE.instantiate()
	scan.set_data(dir)
	if scan != null:
		folders_container.add_child(scan)
		path_lookup[dir] = scan
		scan.removing_scan_view.connect(_remove_path)


func _remove_path(path: String) -> void:
	if path_lookup.has(path):
		path_lookup.erase(path)


func _re_scan() -> void:
	for child: Node in folders_container.get_children():
		child.free()

	path_lookup.clear()

	for path: String in AppState.loaded_paths:
		_add_scan_view(path)

	scan_folders()
