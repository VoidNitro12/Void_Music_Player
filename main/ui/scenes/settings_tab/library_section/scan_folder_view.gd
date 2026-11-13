class_name ScanFolderView
extends SceneBase
## Container class for representing a chosen folder on the users system

signal removing_scan_view(path: String)

@export var path_label: Label
@export var files_found_label: Label
@export var remove_btn: IconBtn
@export var _icon: TextureRect

var _scanner: FileScanner

func set_up_extra_dependencies(scanner: FileScanner) -> void:
	_scanner = scanner

func _configure() -> void:
	super()
	remove_btn.set_bus(_bus)
	
	remove_btn.pressed.connect(
		func() -> void:
			removing_scan_view.emit(path_label.text)
			self.queue_free(),
	)
	
	_icon.self_modulate = AppState.theme_manager.get_current_base_shade()
	
	_bus.ui.change_app_accent_colour.connect(
		func(to: ThemeManager.Accents) -> void:
			_icon.self_modulate = ThemeManager.ACCENT_COLOURS[to],
	)


func set_data(folder_path: String, recursive: bool) -> void:
	if not DirAccess.dir_exists_absolute(folder_path):
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to create a scan view of a non-existent path",
		)
		self.queue_free()
		return

	path_label.text = folder_path
	self.tooltip_text = folder_path
	update_file_count(recursive)
	

func update_file_count(recursive: bool) -> void:
	files_found_label.text = "%d Audio Files" % _scanner.get_valid_audio_files_num(
			path_label.text,
			recursive,
	)
