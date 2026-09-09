@tool
extends RefCounted

var _dictionary
var _splitter
var check_comments := true
var check_strings := true
var check_identifiers := true
var check_filenames := true
var check_folder_names := true
var check_scene_node_names := true
var ignore_short_words := true


func _init(dictionary, splitter) -> void:
	_dictionary = dictionary
	_splitter = splitter


func scan_text(text: String, path: String) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	var triple_delimiter := ""
	var lines := text.split("\n", true)
	for line_index in range(lines.size()):
		var line: String = lines[line_index]
		var column := 0
		while column < line.length():
			if not triple_delimiter.is_empty():
				var triple_end := line.find(triple_delimiter, column)
				if triple_end == -1:
					_check_segment(line.substr(column), column, "string", path, line_index, line, issues)
					break
				_check_segment(line.substr(column, triple_end - column), column, "string", path, line_index, line, issues)
				column = triple_end + 3
				triple_delimiter = ""
				continue

			var character := line[column]
			if character == "#":
				_check_segment(line.substr(column + 1), column + 1, "comment", path, line_index, line, issues)
				break
			if character == "\"" or character == "'":
				var delimiter := character
				if line.substr(column, 3) == delimiter.repeat(3):
					triple_delimiter = delimiter.repeat(3)
					column += 3
					continue
				var closing_quote := _find_closing_quote(line, column + 1, delimiter)
				var content_end := line.length() if closing_quote == -1 else closing_quote
				_check_segment(line.substr(column + 1, content_end - column - 1), column + 1, "string", path, line_index, line, issues)
				if closing_quote == -1:
					break
				column = closing_quote + 1
				continue
			if _is_identifier_start(character):
				var identifier_end := column + 1
				while identifier_end < line.length() and _is_identifier_part(line[identifier_end]):
					identifier_end += 1
				_check_identifier(line.substr(column, identifier_end - column), column, path, line_index, line, issues)
				column = identifier_end
				continue
			column += 1
	return issues


func scan_filename(path: String) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	if not check_filenames:
		return issues
	var basename := path.get_file().get_basename()
	for piece in _splitter.split_identifier(basename):
		_append_if_unknown(piece, "filename", path, -1, basename, issues)
	return issues


func scan_folder_name(path: String) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	if not check_folder_names:
		return issues
	var folder_name := path.trim_suffix("/").get_file()
	for piece in _splitter.split_identifier(folder_name):
		_append_if_unknown(piece, "folder", path, -1, folder_name, issues)
	return issues


func scan_scene_text(text: String, path: String) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	if not check_scene_node_names:
		return issues
	var lines := text.split("\n", true)
	for line_index in range(lines.size()):
		var line: String = lines[line_index]
		if not line.strip_edges().begins_with("[node "):
			continue
		var value_start := line.find("name=\"")
		if value_start < 0:
			continue
		value_start += 6
		var value_end := _find_closing_quote(line, value_start, "\"")
		if value_end < 0:
			continue
		var node_name := line.substr(value_start, value_end - value_start)
		for piece in _splitter.split_identifier(node_name, value_start):
			_append_if_unknown(piece, "scene_node", path, line_index, line, issues)
	return issues


func _check_segment(
	segment: String,
	base_column: int,
	kind: String,
	path: String,
	line_index: int,
	line: String,
	issues: Array[Dictionary]
) -> void:
	if (kind == "comment" and not check_comments) or (kind == "string" and not check_strings):
		return
	for piece in _splitter.split_prose(segment, base_column):
		_append_if_unknown(piece, kind, path, line_index, line, issues)


func _check_identifier(
	identifier: String,
	base_column: int,
	path: String,
	line_index: int,
	line: String,
	issues: Array[Dictionary]
) -> void:
	if not check_identifiers:
		return
	for piece in _splitter.split_identifier(identifier, base_column):
		_append_if_unknown(piece, "identifier", path, line_index, line, issues)


func _append_if_unknown(
	piece: Dictionary,
	kind: String,
	path: String,
	line_index: int,
	context: String,
	issues: Array[Dictionary]
) -> void:
	var word: String = piece.word
	if ignore_short_words and word.length() <= 3:
		return
	if _dictionary.is_known(word, kind == "identifier" or kind == "scene_node"):
		return
	issues.append({
		"id": "%s:%d:%d:%s:%s" % [path, line_index, piece.column, kind, word],
		"path": path,
		"line": line_index,
		"column": piece.column,
		"length": piece.length,
		"word": word,
		"kind": kind,
		"context": context.strip_edges().substr(0, 180),
	})


func _find_closing_quote(line: String, from: int, delimiter: String) -> int:
	var escaped := false
	for index in range(from, line.length()):
		var character := line[index]
		if character == delimiter and not escaped:
			return index
		if character == "\\" and not escaped:
			escaped = true
		else:
			escaped = false
	return -1


func _is_identifier_start(character: String) -> bool:
	return character == "_" or _is_ascii_letter(character)


func _is_identifier_part(character: String) -> bool:
	return _is_identifier_start(character) or character.is_valid_int()


func _is_ascii_letter(character: String) -> bool:
	var code := character.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
