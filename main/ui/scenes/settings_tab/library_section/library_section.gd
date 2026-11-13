class_name LibrarySection
extends SceneBase

## Handles UI for selecting and scanning folders for audio files

const SCAN_FOLDER_VIEW_SCENE: PackedScene = preload(
		"res://main/ui/scenes/settings_tab/library_section/ScanFolderView.tscn"
)

@export var folders_container: VBoxContainer
@export var add_folder_btn: Button
@export var scan_folders_btn: Button
@export var file_dialog: FileDialog

@export_group("Scan Options")
@export var include_sub_dirs_btn: CheckButton

var _library: Library
var _file_scanner: FileScanner
var _settings: Settings
var _library_service: LibrarySettingsService

func set_extra_dependencies(library: Library, file_scanner: FileScanner, settings: Settings) -> void:
	_library = library
	_file_scanner = file_scanner
	_settings = settings

func _configure() -> void:
	add_folder_btn.pressed.connect(_get_folder)
	include_sub_dirs_btn.set_pressed_no_signal(_settings.scan_subdirs)
	include_sub_dirs_btn.toggled.connect(
			_include_sub_dirs_toggled
	)
	scan_folders_btn.pressed.connect(scan_folders)
	file_dialog.dir_selected.connect(_add_scan_view)
	file_dialog.canceled.connect(
			func() -> void:
				add_folder_btn.disabled = false
				scan_folders_btn.disabled = false,
	)

	_bus.data.rescan_loaded_paths.connect(_re_scan)

	_library_service = LibrarySettingsService.new()
	_library_service._set_up_dependencies(_bus, _file_scanner, _settings, _library)


## Scans all the selected folder's for audio, updates AppState and signals for a ui refresh
func scan_folders() -> void:
	_library_service.scan_folders()

func _get_folder() -> void:
	add_folder_btn.disabled = true
	scan_folders_btn.disabled = true
	file_dialog.visible = true


func _add_scan_view(dir: String) -> void:
	add_folder_btn.disabled = false
	scan_folders_btn.disabled = false

	var scan: ScanFolderView = _library_service.add_dir_to_lookup(dir)
	if scan != null:
		folders_container.add_child(scan)
		scan.removing_scan_view.connect(_library_service.remove_dir)


func _re_scan() -> void:
	for child: Node in folders_container.get_children():
		child.free()

	_library_service.clear_lookup()

	for path: String in _settings.loaded_paths:
		_add_scan_view(path)

	scan_folders()


func _include_sub_dirs_toggled(state: bool) -> void:
	_library_service.include_sub_dirs = state
	_settings.scan_subdirs = state
	_bus.data.save_app_data.emit()
