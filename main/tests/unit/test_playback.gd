extends GutTest


func before_each() -> void:
	gut.p("ran setup", 2)


func test_queue_traversal() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)

	var songs: Dictionary[int, Song]

	_make_dummy_songs(songs)

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

	audio_handler.audio_stream.stop()
	audio_handler.free()


func test_queue_deletion() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)

	var songs: Dictionary[int, Song]

	_make_dummy_songs(songs)

	audio_handler.context.set_queue_sources(songs)
	var context: PlaybackContext = audio_handler.context

	context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

	context.break_queue(context.queue)

	for i: QueueItem in context.queue.values():
		assert_eq(i.next, null, "Not all links are broken after breaking the queue")
		assert_eq(i.prev, null, "Not all links are broken after breaking the queue")

	audio_handler.free()


func test_queue_editing() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)

	var songs: Dictionary[int, Song]

	_make_dummy_songs(songs)

	audio_handler.context.set_queue_sources(songs)
	var context: PlaybackContext = audio_handler.context
	context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

	# add to queue
	context.append_to_queue(RequestObj.new(songs[songs.keys()[0]], AppTool.ContextType.SONG, -1))
	assert_true(context.queue.size() == 11, "Size of queue does not match expected")
	
	# reset
	audio_handler.context.set_queue_sources(songs)
	
	# delete from queue
	var head: QueueItem = context.queue[context.queue.keys()[0]]
	var tail: QueueItem = context.queue[context.queue.keys()[-1]]
	var middle: QueueItem = context.queue[context.queue.keys()[5]]
	
	context.remove_from_queue(head.id) 
	assert_true(context.queue.has(head.id) == false, "Head of queue not deleted")
	
	context.remove_from_queue(tail.id) 
	assert_true(context.queue.has(tail.id) == false, "Tail of queue not deleted")
	
	context.remove_from_queue(middle.id) 
	assert_true(context.queue.has(middle.id) == false, "Middle of queue not deleted")
	
	audio_handler.free()


func _make_dummy_songs(songs: Dictionary[int, Song]) -> void:
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
