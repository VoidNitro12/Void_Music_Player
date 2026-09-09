class_name SettingsLibrarySection
extends Panel
## Handles UI for selecting and scanning folders for audio files

@export var scan_line_match: Dictionary[Button, LineEdit]

@export var scan_folders_btn: Button
@export var file_dialog: FileDialog


func _ready() -> void:
	for btn: Button in scan_line_match.keys():
		btn.pressed.connect(_get_folder.bind(btn))
	scan_folders_btn.pressed.connect(scan_folders)


## Scans all the selected folder's for audio, updates AppState and signals for a ui refresh
func scan_folders() -> void:
	var songs: Array[Song]
	for line_edit: LineEdit in scan_line_match.values():
		songs.append_array(FileScanner.get_audio_files(line_edit.text))
	for song: Song in songs:
		AppState.all_tracks[song.id] = song
	AppEvents.refresh_all_tracks.emit()

	for album: Album in FileScanner.get_albums(songs):
		AppState.albums[album.id] = album
	AppEvents.refresh_albums.emit()


func _get_folder(btn: Button) -> void:
	file_dialog.visible = true
	if file_dialog.dir_selected.is_connected(_get_dir_path):
		file_dialog.dir_selected.disconnect(_get_dir_path)
	file_dialog.dir_selected.connect(_get_dir_path.bind(btn), Object.ConnectFlags.CONNECT_ONE_SHOT)


func _get_dir_path(dir: String, btn: Button) -> void:
	if scan_line_match.has(btn):
		scan_line_match[btn].text = dir
