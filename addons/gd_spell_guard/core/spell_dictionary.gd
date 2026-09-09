@tool
extends RefCounted

const HunspellDictionaryScript := preload("res://addons/gd_spell_guard/core/hunspell_dictionary.gd")

const BUILTIN_ROOT := "res://addons/gd_spell_guard/dicts"
const IGNORED_WORDS_PATH := "res://gd_spell_guard/ignored_words.txt"
const FALLBACK_LOCALE := "en_GB"

const LANGUAGE_WORDS := [
	"and", "as", "assert", "await", "break", "breakpoint", "class", "class_name",
	"const", "continue", "elif", "else", "enum", "extends", "false", "for", "func",
	"if", "in", "is", "match", "not", "null", "or", "pass", "preload", "return",
	"self", "signal", "static", "super", "true", "var", "void", "when", "while",
]
const COMMON_CODE_WORDS := [
	"api", "args", "bool", "callback", "config", "ctor", "decrement", "despawn",
	"dict", "enum", "filesystem", "fps", "gdscript", "getter", "gpu", "gui", "http",
	"id", "increment", "init", "int", "lerp", "metadata", "multiplayer", "nav",
	"nullable", "params", "plugin", "prefab", "readonly", "ref", "repo", "rpc",
	"setter", "shader", "stdin", "stdout", "tooltip", "ui", "uid", "uri", "url",
	"utf", "uuid", "viewport", "websocket",
]
const NORMALIZED_CONTRACTIONS := [
	"arent", "cant", "couldnt", "didnt", "doesnt", "dont", "hadnt", "hasnt",
	"havent", "heres", "isnt", "shouldnt", "thats", "theres", "theyre", "wasnt",
	"werent", "whats", "wont", "wouldnt", "youre",
]

var active_locale := FALLBACK_LOCALE
var load_warning := ""
var _hunspell
var _ignored_words: Dictionary = {}
var _code_words: Dictionary = {}
var _splitter


func _init(splitter = null) -> void:
	_splitter = splitter


func load_all(locale: String = FALLBACK_LOCALE, external_root: String = "res://gd_spell_guard_dicts") -> Error:
	_ignored_words.clear()
	_code_words.clear()
	_load_word_file(IGNORED_WORDS_PATH, _ignored_words)
	for word in LANGUAGE_WORDS + COMMON_CODE_WORDS + NORMALIZED_CONTRACTIONS:
		_code_words[word.to_lower()] = true
	_load_godot_api_words()
	var requested_paths := _resolve_locale(locale, external_root)
	var error := _load_hunspell(requested_paths, locale)
	if error == OK:
		load_warning = ""
		return OK
	var fallback_paths := _pair_paths(BUILTIN_ROOT.path_join(FALLBACK_LOCALE), FALLBACK_LOCALE)
	if requested_paths.aff == fallback_paths.aff:
		load_warning = _hunspell.error_message
		return error
	var requested_error: String = _hunspell.error_message
	error = _load_hunspell(fallback_paths, FALLBACK_LOCALE)
	load_warning = "Could not load %s: %s Falling back to %s." % [locale, requested_error, FALLBACK_LOCALE]
	return error


func discover_locales(external_root: String) -> PackedStringArray:
	var locales: Dictionary = {}
	var roots := [BUILTIN_ROOT]
	if external_root.begins_with("res://"):
		roots.append(external_root)
	for root in roots:
		var directory := DirAccess.open(root)
		if directory == null:
			continue
		for folder in directory.get_directories():
			var pair := _pair_paths(root.path_join(folder), folder)
			if FileAccess.file_exists(pair.aff) and FileAccess.file_exists(pair.dic):
				locales[folder] = true
	var result := PackedStringArray(locales.keys())
	result.sort()
	return result


func is_known(word: String, include_code_words: bool = false) -> bool:
	var normalized := normalize(word)
	if normalized.length() <= 1 or (word == word.to_upper() and word.length() > 1):
		return true
	return (
		_ignored_words.has(normalized)
		or (include_code_words and _code_words.has(normalized))
		or (_hunspell != null and _hunspell.is_known(word))
	)


func suggest(word: String, limit: int = 8) -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	var normalized := normalize(word)
	var custom_scores: Dictionary = {}
	for candidate in _ignored_words:
		var distance := _levenshtein(normalized, candidate, 2)
		if distance <= 2:
			custom_scores[candidate] = distance
	for candidate in _code_words:
		var distance := _levenshtein(normalized, candidate, 2)
		if distance <= 2:
			custom_scores[candidate] = min(custom_scores.get(candidate, 99), distance + 1)
	var custom_candidates: Array = custom_scores.keys()
	custom_candidates.sort_custom(func(left, right):
		return custom_scores[left] < custom_scores[right] if custom_scores[left] != custom_scores[right] else left < right
	)
	for candidate in custom_candidates:
		var cased := _apply_case(candidate, word)
		result.append(cased)
		seen[cased.to_lower()] = true
		if result.size() >= limit:
			return result
	if _hunspell != null:
		for candidate in _hunspell.suggest(word, limit):
			if not seen.has(candidate.to_lower()):
				result.append(candidate)
				seen[candidate.to_lower()] = true
			if result.size() >= limit:
				break
	return result


func get_ignored_words() -> PackedStringArray:
	var words := PackedStringArray(_ignored_words.keys())
	words.sort()
	return words


func remove_ignored_word(word: String) -> Error:
	_ignored_words.erase(normalize(word))
	return _write_ignored_words()


func add_ignored_word(word: String) -> Error:
	var normalized := normalize(word)
	if normalized.is_empty():
		return ERR_INVALID_PARAMETER
	_ignored_words[normalized] = true
	return _write_ignored_words()


func _write_ignored_words() -> Error:
	var all_words := PackedStringArray(_ignored_words.keys())
	all_words.sort()
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(IGNORED_WORDS_PATH.get_base_dir())
	)
	if directory_error != OK:
		return directory_error
	var file := FileAccess.open(IGNORED_WORDS_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	for ignored_word in all_words:
		file.store_line(ignored_word)
	return OK


func normalize(word: String) -> String:
	return word.to_lower().replace("'", "").strip_edges()


func _load_hunspell(paths: Dictionary, locale: String) -> Error:
	_hunspell = HunspellDictionaryScript.new()
	var error: Error = _hunspell.load_pair(paths.aff, paths.dic, locale)
	if error == OK:
		active_locale = locale
	return error


func _resolve_locale(locale: String, external_root: String) -> Dictionary:
	if external_root.begins_with("res://"):
		var external := _pair_paths(external_root.path_join(locale), locale)
		if FileAccess.file_exists(external.aff) or FileAccess.file_exists(external.dic):
			return external
	return _pair_paths(BUILTIN_ROOT.path_join(locale), locale)


func _pair_paths(root: String, locale: String) -> Dictionary:
	return {"aff": root.path_join(locale + ".aff"), "dic": root.path_join(locale + ".dic")}


func _load_word_file(path: String, target: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	while file != null and not file.eof_reached():
		var word := normalize(file.get_line())
		if not word.is_empty() and not word.begins_with("#"):
			target[word] = true


func _load_godot_api_words() -> void:
	for type_name in ClassDB.get_class_list():
		_add_code_identifier(type_name)
		for method_info in ClassDB.class_get_method_list(type_name, true):
			_add_code_identifier(method_info.get("name", ""))
		for property_info in ClassDB.class_get_property_list(type_name, true):
			_add_code_identifier(property_info.get("name", ""))
		for signal_info in ClassDB.class_get_signal_list(type_name, true):
			_add_code_identifier(signal_info.get("name", ""))
		for constant_name in ClassDB.class_get_integer_constant_list(type_name, true):
			_add_code_identifier(constant_name)


func _add_code_identifier(identifier: String) -> void:
	if identifier.is_empty():
		return
	_code_words[normalize(identifier)] = true
	if _splitter != null:
		for piece in _splitter.split_identifier(identifier):
			_code_words[normalize(piece.word)] = true


func _levenshtein(left: String, right: String, maximum: int) -> int:
	if abs(left.length() - right.length()) > maximum:
		return maximum + 1
	var previous: Array[int] = []
	for index in range(right.length() + 1):
		previous.append(index)
	for left_index in range(1, left.length() + 1):
		var current: Array[int] = [left_index]
		var row_min := left_index
		for right_index in range(1, right.length() + 1):
			var cost := 0 if left[left_index - 1] == right[right_index - 1] else 1
			var value: int = min(previous[right_index] + 1, current[right_index - 1] + 1, previous[right_index - 1] + cost)
			current.append(value)
			row_min = min(row_min, value)
		if row_min > maximum:
			return maximum + 1
		previous = current
	return previous[right.length()]


func _apply_case(word: String, original: String) -> String:
	if original == original.to_upper():
		return word.to_upper()
	if not original.is_empty() and original[0] == original[0].to_upper():
		return word.capitalize()
	return word
