class_name ScanFolderView
extends Panel
## Container class for representing a chosen folder on the users system

@export var path_label: Label
@export var files_found_label: Label
@export var remove_btn: Button

signal removing_scan_view(path: String)

func _ready() -> void:
	remove_btn.pressed.connect(
		func() -> void:
			removing_scan_view.emit(path_label.text)
			self.queue_free(),
	)


func set_data(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path):
		AppEvents.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to create a scan view of a non-existent path",
		)
		self.queue_free()
		return
	
	path_label.text = folder_path
	self.tooltip_text = folder_path
	files_found_label.text = "%d Audio Files"%_get_valid_audio_files_size(folder_path)

func _get_valid_audio_files_size(path: String) -> int: 
	var valid_files: PackedStringArray
	var all_files: PackedStringArray = DirAccess.get_files_at(path)
	var valid_extensions: PackedStringArray = FileScanner.get_valid_extensions()
	for file_name: String in all_files: 
		if file_name.get_extension().to_lower() in valid_extensions: 
			valid_files.append(file_name)
	
	return valid_files.size()
