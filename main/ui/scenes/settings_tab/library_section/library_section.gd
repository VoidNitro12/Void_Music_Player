class_name SettingsLibrarySection
extends Panel
## Handles UI for selecting and scanning folders for audio files

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


## Scans all the selected folder's for audio, updates AppState and signals for a ui refresh
func scan_folders() -> void:
	var paths: PackedStringArray

	for path: String in path_lookup.keys():
		paths.append(path)

	var _scan_task_id: int = WorkerThreadPool.add_task(_scan.bind(paths))
	AppEvents.start_loading_wait.emit()


func _scan(paths: PackedStringArray) -> void:
	var songs: Array[Song]
	for path: String in paths:
		songs.append_array(FileScanner.get_audio_files(path))

	call_deferred("_handle_found_songs", songs)


func _handle_found_songs(songs: Array[Song]) -> void:
	for song: Song in songs:
		AppState.all_tracks[song.id] = song
	AppEvents.refresh_all_tracks.emit()

	for album: Album in FileScanner.get_albums(songs):
		AppState.albums[album.id] = album
	AppEvents.refresh_albums.emit()

	AppEvents.end_loading_wait.emit()


func _get_folder() -> void:
	file_dialog.visible = true
	if file_dialog.dir_selected.is_connected(_add_scan_view):
		file_dialog.dir_selected.disconnect(_add_scan_view)
	file_dialog.dir_selected.connect(_add_scan_view, Object.ConnectFlags.CONNECT_ONE_SHOT)


func _add_scan_view(dir: String) -> void:
	if path_lookup.has(dir):
		AppEvents.log_error.emit(
			AppTool.LogLevels.WARN,
			"Attempted to add an existing path to dcan folders",
		)
		return

	var scan: ScanFolderView = FullScreenPlayer.SCAN_FOLDER_VIEW_SCENE.instantiate()
	scan.set_data(dir)
	if scan != null:
		folders_container.add_child(scan)
		path_lookup[dir] = scan
		scan.removing_scan_view.connect(_remove_path)


func _remove_path(path: String) -> void:
	if path_lookup.has(path):
		path_lookup.erase(path)
