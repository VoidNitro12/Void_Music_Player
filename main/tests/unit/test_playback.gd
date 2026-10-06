extends GutTest


func before_each() -> void:
	gut.p("ran setup", 2)


func test_queue_traversal() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)

	var songs: Dictionary[int, Song]

	# Create dummy songs
	for i: int in range(10):
		var audio_dict: Dictionary = AppState.file_scanner.get_audio_dict_from_path(
			ProjectSettings.globalize_path("res://main/tests/unit/song_object/test_audio.mp3")
		)
		# Not using AppStates create song from audio dict as that would produce only one song
		# regardless of how many times its called
		var song: Song = Song.new()
		song.id = i
		song.path = audio_dict.get("path", "")
		song.cover_path = audio_dict.get("cover_path", "")
		song.title = audio_dict.get("title", "")
		song.artist = audio_dict.get("artist", "")
		song.album = audio_dict.get("album", "")
		song.release_year = audio_dict.get("release_year", 0)
		song.raw_length = audio_dict.get("raw_length", 0)
		songs[song.id] = song

	audio_handler.context.set_queue_sources(songs)
	var context: PlaybackContext = audio_handler.context

	var expected_queue_idx: int = 5

	audio_handler.play_song(
		RequestObj.new(songs.values()[expected_queue_idx], AppTool.ContextType.SONG, -1)
	)

	context.cursor.jump_to(expected_queue_idx, context.queue) # the first assert confirms if jump
	# to worked

	# unless shuffled the queue dictionary is ordered
	gut.p("Current song position in queue is %d" % context.cursor.item.id)
	assert_eq(
		context.cursor.item.id,
		expected_queue_idx,
		"Current songs position in the current queue is not expected",
	)

	audio_handler.next_in_queue()
	expected_queue_idx += 1
	assert_eq(
		context.cursor.item.id,
		expected_queue_idx,
		"Current songs position in the current queue is not expected after advancing by 1",
	)

	audio_handler.prev_in_queue()
	expected_queue_idx -= 1
	assert_eq(
		context.cursor.item.id,
		expected_queue_idx,
		"Current songs position in the current queue is not expected after backtracking by 1",
	)

	audio_handler.free()
