@tool
extends RefCounted

var locale := ""
var error_message := ""
var try_characters := ""
var replacements: Array[PackedStringArray] = []

var _roots: Dictionary = {}
var _prefix_rules: Dictionary = {}
var _suffix_rules: Dictionary = {}
var _prefix_by_add: Dictionary = {}
var _suffix_by_add: Dictionary = {}
const SPECIAL_FLAG_DEFAULTS := {
	"NOSUGGEST": "",
	"NEEDAFFIX": "",
	"ONLYINCOMPOUND": "",
	"FORBIDDENWORD": "",
	"KEEPCASE": "",
}
var _special_flags := SPECIAL_FLAG_DEFAULTS.duplicate()
var _iconv: Array[PackedStringArray] = []
var _oconv: Array[PackedStringArray] = []
var _candidate_index: Dictionary = {}
var _suggestion_cache: Dictionary = {}
var _keepcase_roots: Dictionary = {}
var _flag_mode := "char"
var _aliases: Array[String] = [""]
var _alias_lines_remaining := 0


func load_pair(aff_path: String, dic_path: String, dictionary_locale: String) -> Error:
	locale = dictionary_locale
	error_message = ""
	_roots.clear()
	_prefix_rules.clear()
	_suffix_rules.clear()
	_prefix_by_add.clear()
	_suffix_by_add.clear()
	_candidate_index.clear()
	_suggestion_cache.clear()
	_keepcase_roots.clear()
	_special_flags = SPECIAL_FLAG_DEFAULTS.duplicate()
	_flag_mode = "char"
	_aliases = [""]
	_alias_lines_remaining = 0
	replacements.clear()
	_iconv.clear()
	_oconv.clear()
	if not FileAccess.file_exists(aff_path) or not FileAccess.file_exists(dic_path):
		error_message = "Missing .aff or .dic file for %s." % dictionary_locale
		return ERR_FILE_NOT_FOUND
	var error := _load_aff(aff_path)
	if error != OK:
		return error
	return _load_dic(dic_path)


func is_known(word: String) -> bool:
	var converted := _apply_conversions(word, _iconv)
	var normalized := converted.to_lower()
	if _root_allows(normalized, "", true) and (not _keepcase_roots.has(normalized) or _keepcase_roots[normalized] == converted):
		return true
	if _matches_affix(normalized, _prefix_by_add, true):
		return true
	if _matches_affix(normalized, _suffix_by_add, false):
		return true
	return _matches_cross_product(normalized)


func suggest(word: String, limit: int = 8) -> Array[String]:
	var normalized := word.to_lower()
	var cache_key := "%s:%d" % [normalized, limit]
	if _suggestion_cache.has(cache_key):
		return _apply_case_to_list(_suggestion_cache[cache_key], word)
	var scores: Dictionary = {}
	for pair in replacements:
		var source: String = pair[0]
		var target: String = pair[1]
		if source in normalized:
			var candidate := normalized.replace(source, target)
			if is_known(candidate):
				scores[candidate] = min(scores.get(candidate, 999), 0)
	for candidate in _candidate_pool(normalized):
		if candidate == normalized:
			continue
		var distance := _damerau_levenshtein(normalized, candidate, 3)
		if distance <= 3:
			var prefix_bonus := 0 if candidate[0] == normalized[0] else 2
			scores[candidate] = min(scores.get(candidate, 999), distance * 10 + prefix_bonus)
	var ranked: Array = scores.keys()
	ranked.sort_custom(func(left, right):
		var left_score: int = scores[left]
		var right_score: int = scores[right]
		return left_score < right_score if left_score != right_score else left < right
	)
	var result: Array[String] = []
	for candidate in ranked:
		if result.size() >= limit:
			break
		result.append(_apply_conversions(candidate, _oconv))
	_suggestion_cache[cache_key] = result.duplicate()
	return _apply_case_to_list(result, word)


func _load_aff(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "Could not open %s." % path
		return FileAccess.get_open_error()
	var current_kind := ""
	var current_flag := ""
	var current_cross := false
	while not file.eof_reached():
		var line := _strip_bom(file.get_line()).strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		var directive: String = parts[0]
		if directive == "FLAG" and parts.size() >= 2:
			_flag_mode = parts[1].to_lower()
			continue
		if directive == "AF" and parts.size() >= 2:
			if _alias_lines_remaining == 0 and parts[1].is_valid_int():
				_alias_lines_remaining = parts[1].to_int()
			else:
				_aliases.append(parts[1])
				_alias_lines_remaining = max(0, _alias_lines_remaining - 1)
			continue
		if directive in ["PFX", "SFX"] and parts.size() == 4:
			current_kind = directive
			current_flag = parts[1]
			current_cross = parts[2] == "Y"
			continue
		if directive in ["PFX", "SFX"] and parts.size() >= 5:
			var flag: String = parts[1]
			var rule := {
				"flag": flag,
				"strip": "" if parts[2] == "0" else parts[2],
				"add": ("" if parts[3] == "0" else parts[3]).split("/")[0],
				"condition": parts[4],
				"cross": current_cross if current_kind == directive and current_flag == flag else false,
			}
			var target: Dictionary = _prefix_rules if directive == "PFX" else _suffix_rules
			var by_add: Dictionary = _prefix_by_add if directive == "PFX" else _suffix_by_add
			if not target.has(flag):
				target[flag] = []
			target[flag].append(rule)
			if not by_add.has(rule.add):
				by_add[rule.add] = []
			by_add[rule.add].append(rule)
			continue
		if directive in _special_flags and parts.size() >= 2:
			_special_flags[directive] = parts[1]
		elif directive == "TRY" and parts.size() >= 2:
			try_characters = parts[1]
		elif directive == "REP" and parts.size() >= 3 and parts[1].is_valid_int() == false:
			replacements.append(PackedStringArray([parts[1], parts[2]]))
		elif directive in ["ICONV", "OCONV"] and parts.size() >= 3 and parts[1].is_valid_int() == false:
			var conversions: Array = _iconv if directive == "ICONV" else _oconv
			conversions.append(PackedStringArray([parts[1], parts[2]]))
	return OK


func _load_dic(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "Could not open %s." % path
		return FileAccess.get_open_error()
	var first_line := true
	while not file.eof_reached():
		var line := _strip_bom(file.get_line()).strip_edges()
		if first_line:
			first_line = false
			if line.is_valid_int():
				continue
		if line.is_empty():
			continue
		var entry := line.split("\t", false)[0]
		var slash := entry.find("/")
		var root := entry if slash < 0 else entry.substr(0, slash)
		var flags := "" if slash < 0 else entry.substr(slash + 1)
		if flags.is_valid_int() and flags.to_int() > 0 and flags.to_int() < _aliases.size():
			flags = _aliases[flags.to_int()]
		root = _apply_conversions(root, _iconv).to_lower()
		_roots[root] = _merge_flags(_roots.get(root, ""), flags)
		if _has_flag(flags, _special_flags.KEEPCASE):
			_keepcase_roots[root] = entry if slash < 0 else entry.substr(0, slash)
		if (
			not _has_flag(flags, _special_flags.NOSUGGEST)
			and not _has_flag(flags, _special_flags.ONLYINCOMPOUND)
			and not _has_flag(flags, _special_flags.FORBIDDENWORD)
			and not _has_flag(flags, _special_flags.KEEPCASE)
		):
			var key := _candidate_key(root)
			if not _candidate_index.has(key):
				_candidate_index[key] = []
			_candidate_index[key].append(root)
	if _roots.is_empty():
		error_message = "Dictionary %s contains no words." % locale
		return ERR_FILE_CORRUPT
	return OK


func _matches_affix(word: String, by_add: Dictionary, prefix: bool) -> bool:
	for add in by_add:
		if (prefix and word.begins_with(add)) or (not prefix and word.ends_with(add)):
			for rule in by_add[add]:
				var root := _reverse_rule(word, rule, prefix)
				if not root.is_empty() and _root_allows(root, rule.flag):
					return true
	return false


func _matches_cross_product(word: String) -> bool:
	for suffix_add in _suffix_by_add:
		if not word.ends_with(suffix_add):
			continue
		for suffix_rule in _suffix_by_add[suffix_add]:
			if not suffix_rule.cross:
				continue
			var without_suffix := _reverse_rule(word, suffix_rule, false)
			if without_suffix.is_empty():
				continue
			for prefix_add in _prefix_by_add:
				if not without_suffix.begins_with(prefix_add):
					continue
				for prefix_rule in _prefix_by_add[prefix_add]:
					if not prefix_rule.cross:
						continue
					var root := _reverse_rule(without_suffix, prefix_rule, true)
					if _root_allows(root, prefix_rule.flag) and _has_flag(_roots[root], suffix_rule.flag):
						return true
	return false


func _reverse_rule(word: String, rule: Dictionary, prefix: bool) -> String:
	var add: String = rule.add
	var root := ""
	if prefix:
		if not word.begins_with(add):
			return ""
		root = rule.strip + word.substr(add.length())
	else:
		if not word.ends_with(add):
			return ""
		root = word.substr(0, word.length() - add.length()) + rule.strip
	var regex := RegEx.new()
	var condition: String = rule.condition
	var expression := "^%s" % condition if prefix else "%s$" % condition
	if regex.compile(expression) != OK or regex.search(root) == null:
		return ""
	return root


func _root_allows(root: String, required_flag: String, allow_keepcase: bool = false) -> bool:
	if not _roots.has(root):
		return false
	var flags: String = _roots[root]
	if _has_flag(flags, _special_flags.FORBIDDENWORD) or _has_flag(flags, _special_flags.ONLYINCOMPOUND):
		return false
	if not allow_keepcase and _has_flag(flags, _special_flags.KEEPCASE):
		return false
	if required_flag.is_empty() and _has_flag(flags, _special_flags.NEEDAFFIX):
		return false
	return required_flag.is_empty() or _has_flag(flags, required_flag)


func _has_flag(flags: String, flag: String) -> bool:
	if flag.is_empty():
		return false
	if _flag_mode == "num":
		return flag in flags.split(",", false)
	if _flag_mode == "long":
		for index in range(0, flags.length(), 2):
			if flags.substr(index, 2) == flag:
				return true
		return false
	return flag in flags


func _merge_flags(existing: String, incoming: String) -> String:
	var merged: Array[String] = _flag_tokens(existing)
	for flag in _flag_tokens(incoming):
		if flag not in merged:
			merged.append(flag)
	if _flag_mode == "num":
		return ",".join(merged)
	return "".join(merged)


func _flag_tokens(flags: String) -> Array[String]:
	var result: Array[String] = []
	if _flag_mode == "num":
		for flag in flags.split(",", false):
			result.append(flag)
	elif _flag_mode == "long":
		for index in range(0, flags.length(), 2):
			result.append(flags.substr(index, 2))
	else:
		for flag in flags:
			result.append(flag)
	return result


func _candidate_pool(word: String) -> Array[String]:
	var candidates: Dictionary = {}
	var first := word.substr(0, 1)
	for length in range(max(1, word.length() - 2), word.length() + 3):
		var key := "%s:%d" % [first, length]
		for root in _candidate_index.get(key, []):
			if _root_allows(root, "", true):
				candidates[root] = true
			for form in _forward_forms(root):
				if abs(form.length() - word.length()) <= 3:
					candidates[form] = true
	var result: Array[String] = []
	for candidate in candidates:
		result.append(candidate)
	return result


func _forward_forms(root: String) -> Array[String]:
	var forms: Dictionary = {}
	var flags: String = _roots.get(root, "")
	for flag in _flag_tokens(flags):
		for rule in _prefix_rules.get(flag, []):
			var prefix_form := _apply_rule(root, rule, true)
			if not prefix_form.is_empty():
				forms[prefix_form] = true
		for rule in _suffix_rules.get(flag, []):
			var suffix_form := _apply_rule(root, rule, false)
			if not suffix_form.is_empty():
				forms[suffix_form] = true
	var result: Array[String] = []
	for form in forms:
		result.append(form)
	return result


func _apply_rule(root: String, rule: Dictionary, prefix: bool) -> String:
	var regex := RegEx.new()
	var expression := "^%s" % rule.condition if prefix else "%s$" % rule.condition
	if regex.compile(expression) != OK or regex.search(root) == null:
		return ""
	var strip: String = rule.strip
	if prefix:
		if not strip.is_empty() and not root.begins_with(strip):
			return ""
		return rule.add + root.substr(strip.length())
	if not strip.is_empty() and not root.ends_with(strip):
		return ""
	return root.substr(0, root.length() - strip.length()) + rule.add


func _candidate_key(word: String) -> String:
	var first := word.substr(0, 1) if not word.is_empty() else "*"
	return "%s:%d" % [first, word.length()]


func _damerau_levenshtein(left: String, right: String, maximum: int) -> int:
	if abs(left.length() - right.length()) > maximum:
		return maximum + 1
	var previous: Array[int] = []
	var current: Array[int] = []
	var before_previous: Array[int] = []
	for index in range(right.length() + 1):
		previous.append(index)
	for left_index in range(1, left.length() + 1):
		current = [left_index]
		var row_min := left_index
		for right_index in range(1, right.length() + 1):
			var cost := 0 if left[left_index - 1] == right[right_index - 1] else 1
			var value: int = min(previous[right_index] + 1, current[right_index - 1] + 1, previous[right_index - 1] + cost)
			if left_index > 1 and right_index > 1 and left[left_index - 1] == right[right_index - 2] and left[left_index - 2] == right[right_index - 1]:
				value = min(value, before_previous[right_index - 2] + 1)
			current.append(value)
			row_min = min(row_min, value)
		if row_min > maximum:
			return maximum + 1
		before_previous = previous
		previous = current
	return previous[right.length()]


func _apply_conversions(word: String, conversions: Array[PackedStringArray]) -> String:
	var result := word
	for pair in conversions:
		result = result.replace(pair[0], pair[1])
	return result


func _apply_case_to_list(words: Array[String], original: String) -> Array[String]:
	var result: Array[String] = []
	for word in words:
		if original == original.to_upper():
			result.append(word.to_upper())
		elif original.length() > 0 and original[0] == original[0].to_upper():
			result.append(word.capitalize())
		else:
			result.append(word)
	return result


func _strip_bom(value: String) -> String:
	return value.trim_prefix("\ufeff")
