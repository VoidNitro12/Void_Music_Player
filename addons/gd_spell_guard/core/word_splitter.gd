@tool
extends RefCounted

var _identifier_piece_regex := RegEx.new()
var _prose_token_regex := RegEx.new()


func _init() -> void:
	_identifier_piece_regex.compile("[A-Z]+(?=[A-Z][a-z]|[0-9]|$)|[A-Z]?[a-z]+|[A-Z]+|[0-9]+")
	_prose_token_regex.compile("[A-Za-z][A-Za-z0-9_'-]*")


func split_identifier(identifier: String, base_column: int = 0) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for match_result in _identifier_piece_regex.search_all(identifier):
		var word := match_result.get_string()
		if word.is_empty() or word.is_valid_int():
			continue
		pieces.append({
			"word": word,
			"column": base_column + match_result.get_start(),
			"length": match_result.get_end() - match_result.get_start(),
		})
	return pieces


func split_prose(text: String, base_column: int = 0) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for token_match in _prose_token_regex.search_all(text):
		if _looks_like_path_url_or_hash(text, token_match.get_start(), token_match.get_end()):
			continue
		var token := token_match.get_string()
		var trim := _trim_token_edges(token)
		if trim.word.is_empty():
			continue
		if "'" in token:
			pieces.append({
				"word": trim.word,
				"column": base_column + token_match.get_start() + trim.start,
				"length": trim.word.length(),
			})
			continue
		for piece in split_identifier(trim.word, base_column + token_match.get_start() + trim.start):
			pieces.append(piece)
	return pieces


func _looks_like_path_url_or_hash(text: String, start: int, end: int) -> bool:
	var chunk_start := start
	var chunk_end := end
	while chunk_start > 0 and not _is_boundary(text[chunk_start - 1]):
		chunk_start -= 1
	while chunk_end < text.length() and not _is_boundary(text[chunk_end]):
		chunk_end += 1
	var chunk := text.substr(chunk_start, chunk_end - chunk_start)
	var lower_chunk := chunk.to_lower()
	if "://" in chunk or "/" in chunk or "\\" in chunk or "@" in chunk:
		return true
	if lower_chunk.begins_with("0x"):
		return true
	var hash_index := chunk.find("#")
	if hash_index >= 0:
		var hex_length := 0
		for index in range(hash_index + 1, chunk.length()):
			if chunk[index].to_lower() not in "0123456789abcdef":
				break
			hex_length += 1
		if hex_length >= 6:
			return true
	var extension := lower_chunk.get_extension()
	return extension in ["gd", "tscn", "tres", "res", "svg", "png", "jpg", "jpeg", "webp", "json", "csv", "txt", "md"]


func _is_boundary(character: String) -> bool:
	return character in [" ", "\t", "\r", "\n", "(", ")", "[", "]", "{", "}", ",", ";"]


func _trim_token_edges(token: String) -> Dictionary:
	var start := 0
	var end := token.length()
	while start < end and not _is_ascii_alphanumeric(token[start]):
		start += 1
	while end > start and not _is_ascii_alphanumeric(token[end - 1]):
		end -= 1
	return {
		"word": token.substr(start, end - start),
		"start": start,
	}


func _is_ascii_alphanumeric(character: String) -> bool:
	return character.is_valid_int() or character.to_lower() in "abcdefghijklmnopqrstuvwxyz"
