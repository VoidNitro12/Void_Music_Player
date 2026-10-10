extends GutTest


func before_each() -> void:
	gut.p("ran setup", 2)


func test_queue_traversal() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)

	var songs: Dictionary[int, Song]

	_make_dummy_songs(songs, 10)

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

	_make_dummy_songs(songs, 10)

	audio_handler.context.set_queue_sources(songs)
	var context: PlaybackContext = audio_handler.context

	context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

	context.break_queue(context.queue)

	for i: QueueItem in context.queue.values():
		assert_eq(i.next, null, "Not all links are broken after breaking the queue")
		assert_eq(i.prev, null, "Not all links are broken after breaking the queue")

	audio_handler.free()


func test_queue_add_item() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)
	var context: PlaybackContext = audio_handler.context

	var songs: Dictionary[int, Song]

	var queue_sizes: PackedInt64Array = [0, 1, 10]

	_make_dummy_songs(songs, 1)
	var song_to_add: Song = songs[0]

	songs.clear()

	for i: int in queue_sizes:
		_make_dummy_songs(songs, i)

		audio_handler.context.set_queue_sources(songs)
		if i > 0:
			context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

		gut.p("Expected queue size: %d" % i)
		gut.p("Number of songs in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")

		context.append_to_queue(RequestObj.new(song_to_add, AppTool.ContextType.SONG, -1))
		assert_eq(context.queue.size(), i + 1, "Size of queue does not match expected")

		songs.clear()

	audio_handler.free()


func test_queue_insert_next() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)
	var context: PlaybackContext = audio_handler.context

	var songs: Dictionary[int, Song]

	var queue_sizes: PackedInt64Array = [0, 1, 10]

	_make_dummy_songs(songs, 1)
	var out_song_to_insert: Song = songs[0] #song to insert from outside the queue
	songs.clear()

	for i: int in queue_sizes:
		_make_dummy_songs(songs, i)

		audio_handler.context.set_queue_sources(songs)
		if i > 0:
			context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

		gut.p("Expected queue size: %d" % i)
		gut.p("Number of songs in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")
		var size_of_queue: int = context.queue.size()

		# set the cursor to imitate a playing song
		if i > 0:
			context.cursor.item = context.queue.values()[
				context.queue.keys()[randi() % context.queue.size()]
			]

		# inserting a song from outside the queue
		context.insert_next(RequestObj.new(out_song_to_insert, AppTool.ContextType.SONG))
		assert_eq(
			context.queue.size(),
			size_of_queue + 1,
			"Number of songs in queue does not match expected",
		)
		size_of_queue += 1

		if i > 0:
			assert_eq(
				context.cursor.item.next.song,
				out_song_to_insert,
				"Next song in queue does not match inserted",
			)
		else:
			assert_eq(
				context.queue[context.queue.keys()[0]].song,
				out_song_to_insert,
				"Sole song in queue is not what was expected",
			)

		# insering a song from inside the queue
		if i > 1:
			var in_song_to_insert: Song = context \
					.queue[context.queue.keys()[randi() % context.queue.keys().size()]] \
					.song
			context.insert_next(RequestObj.new(in_song_to_insert, AppTool.ContextType.SONG))
			assert_eq(
				context.queue.size(),
				size_of_queue + 1,
				"Number of songs in queue does not match expected",
			)
			assert_eq(
				context.cursor.item.next.song,
				in_song_to_insert,
				"Next song in queue does not match inserted",
			)

	audio_handler.free()


func test_queue_delete_item() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)
	var context: PlaybackContext = audio_handler.context

	var songs: Dictionary[int, Song]

	# not adding a 0 check cause the option doesnt appear, and also
	# nothing happens
	var queue_sizes: PackedInt64Array = [1, 2, 5, 10]

	for i: int in queue_sizes:
		_make_dummy_songs(songs, i)

		audio_handler.context.set_queue_sources(songs)
		context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

		gut.p("Expected queue size: %d" % i)
		gut.p("Number of songs in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")
		var size_of_queue: int = context.queue.size()

		# remove head
		context.remove_from_queue(context.queue.keys()[0])
		assert_eq(context.queue.size(), size_of_queue - 1, "Size of queue does not match expected")
		size_of_queue -= 1

		if i > 2:
			# remove tail
			context.remove_from_queue(context.queue.keys()[-1])
			assert_eq(
				context.queue.size(),
				size_of_queue - 1,
				"Size of queue does not match expected",
			)
			size_of_queue -= 1

			# remove middle
			context.remove_from_queue(
				context.queue.keys()[randi() % (context.queue.size() - 1) + 1]
			)
			assert_eq(
				context.queue.size(),
				size_of_queue - 1,
				"Size of queue does not match expected",
			)
			size_of_queue -= 1

		songs.clear()

	audio_handler.free()


func _make_dummy_songs(songs: Dictionary[int, Song], num: int) -> void:
	for i: int in range(num):
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
