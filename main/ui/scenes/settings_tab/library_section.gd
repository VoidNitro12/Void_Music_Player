class_name SettingsLibrarySection
extends Panel

@export var scan_line_match: Dictionary[Button,LineEdit]

@export var scan_folders_btn: Button
@export var file_dialog: FileDialog


func _ready() -> void:
	for btn: Button in scan_line_match.keys():
		btn.pressed.connect(get_folder.bind(btn))
	scan_folders_btn.pressed.connect(scan_folders)


func get_folder(btn: Button) -> void: 
	file_dialog.visible = true
	if file_dialog.dir_selected.is_connected(get_dir_path):
		file_dialog.dir_selected.disconnect(get_dir_path)
	file_dialog.dir_selected.connect(get_dir_path.bind(btn), Object.ConnectFlags.CONNECT_ONE_SHOT)

func get_dir_path(dir: String, btn: Button) -> void: 
	if scan_line_match.has(btn):
		scan_line_match[btn].text = dir

func scan_folders() ->void: 
	for line_edit: LineEdit in scan_line_match.values():
		AppState.all_tracks.append_array(FileScanner.get_audio_files(line_edit.text))
	AppEvents.all_tracks_set.emit()
	
	AppState.albums = FileScanner.get_albums(AppState.all_tracks)
	AppEvents.all_albums_set.emit()
