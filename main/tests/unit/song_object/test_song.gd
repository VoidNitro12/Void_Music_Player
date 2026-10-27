extends GutTest


func before_each() -> void:
	gut.p("ran setup", 2)


func test_song_creation() -> void:
	var logger: ErrorLogger = ErrorLogger.new()
	logger.set_session_id("TEST")
	var scanner: FileScanner = FileScanner.new()
	scanner.set_error_logger(logger)
	var audio_dict: Dictionary = scanner.get_audio_dict_from_path(
		ProjectSettings.globalize_path("res://main/tests/unit/song_object/test_audio.mp3")
	)
	assert_eq(audio_dict.get("title", ""), "test_audio", "Unexpected title")
	assert_eq(audio_dict.get("artist", ""), "VoidNitro12", "Unexpected artist")
	assert_eq(audio_dict.get("album", ""), "Testing", "Unexpected album")
	assert_eq(audio_dict.get("raw_length", 0), 30, "Unexpected duration")
