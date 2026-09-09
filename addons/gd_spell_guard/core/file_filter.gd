@tool
extends RefCounted


static func is_generated_or_hidden(path: String) -> bool:
	var filename := path.get_file()
	return filename.begins_with(".") or path.get_extension().to_lower() in ["uid", "import"]


static func is_excluded(path: String, always_excluded_paths: Array, excluded_paths: Array, generated_root: String) -> bool:
	if not generated_root.is_empty() and (path == generated_root or path.begins_with(generated_root + "/")):
		return true
	for excluded_path in always_excluded_paths:
		if _matches_excluded_path(path, excluded_path):
			return true
	for excluded_path in excluded_paths:
		if _matches_excluded_path(path, excluded_path):
			return true
	return false


static func should_check_file(path: String, always_excluded_paths: Array, excluded_paths: Array, generated_root: String) -> bool:
	return not is_generated_or_hidden(path) and not is_excluded(path, always_excluded_paths, excluded_paths, generated_root)


static func _matches_excluded_path(path: String, excluded_path: String) -> bool:
	return path == excluded_path or path.begins_with(excluded_path + "/")
