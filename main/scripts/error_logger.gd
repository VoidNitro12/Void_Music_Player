class_name ErrorLogger
extends RefCounted
## System for handling logging of app errors

## Number of files the logger will store in the file before clearing old ones
const MAX_LOG_FILES: int = 10


## Logs an error into the current log file or makes a new one if it doesnt exist.[br]
## [b]NOTE:[/b] Errors meant to be shown to the user are not handled here and should be implemented
## by the caller
static func log_error(level: AppTool.LogLevels, message: String) -> void:
	var time_stamp: String = Time.get_datetime_string_from_system(true,true)
	var error_message: String = "[%s] :  %s--%s" % [
		AppTool.LogLevels.keys()[level],
		time_stamp,
		message,
	]
	var log_file_name: String = AppState.session_id + ".txt"
	var prev_logs: PackedStringArray = _get_old_logs()
	if not prev_logs.has(log_file_name):
		_create_log(log_file_name, error_message)
		if _get_old_logs().size() > MAX_LOG_FILES:
			_clear_old_logs(prev_logs)
		return

	_append_log(log_file_name, error_message)


static func _append_log(log_file_name: String, error_message: String) -> void:
	var path: String = AppState.ERROR_LOG_PATH.path_join(log_file_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		push_error("Unable to access log, error: %s" % FileAccess.get_open_error())
		return
	file.seek_end()
	var result: bool = file.store_line(error_message)
	if not result:
		push_error("Could not append to file")
		return
	file.flush()


static func _create_log(log_file_name: String, error_message: String) -> void:
	var path: String = AppState.ERROR_LOG_PATH.path_join(log_file_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to access log, error: %s" % FileAccess.get_open_error())
		return
	var new_log_content: String = "version: %s\nsession_id: %s\n\t----LOGS----\n%s" % [
		ProjectSettings.get_setting("application/config/version"),
		AppState.session_id,
		error_message,
	]
	file.store_line(new_log_content)
	file.flush()


static func _get_old_logs() -> PackedStringArray:
	var temp: PackedStringArray = DirAccess.get_files_at(AppState.ERROR_LOG_PATH)
	var prev_logs: PackedStringArray = []
	for path: String in temp:
		if path.begins_with(AppTool.LOG_FILE_PREFIX):
			prev_logs.append(path)
	return prev_logs


static func _clear_old_logs(prev_logs: PackedStringArray) -> void:
	var mod_log: Array[Dictionary]

	for file_name: String in prev_logs:
		var path: String = AppState.ERROR_LOG_PATH.path_join(file_name)
		var mod_time: int = FileAccess.get_modified_time(path)
		var entry: Dictionary = { "mod_time": mod_time, "path": path }
		mod_log.append(entry)

	mod_log.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.mod_time < b.mod_time,
	)
	var dir: DirAccess = DirAccess.open(AppState.ERROR_LOG_PATH)
	var result: Error = dir.remove(mod_log.pop_front().path)
	if result != OK:
		push_error("Could not delete oldest log")
