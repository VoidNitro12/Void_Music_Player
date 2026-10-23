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

		gut.p("--Testing append_to_queue with %d dummy songs in queue" % i)
		gut.p("Number of songs actually in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")

		context.append_to_queue(RequestObj.new(song_to_add, AppTool.ContextType.SONG, -1))
		assert_eq(context.queue.size(), i + 1, "Size of queue does not match expected")

		songs.clear()
		gut.p("Done\n")

	audio_handler.free()


func test_queue_insert_next() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)
	var context: PlaybackContext = audio_handler.context

	var songs: Dictionary[int, Song]

	var queue_sizes: PackedInt64Array = [0, 1, 10]

	var out_song_to_insert: Song = _make_dummy_song()

	for i: int in queue_sizes:
		_make_dummy_songs(songs, i)

		audio_handler.context.set_queue_sources(songs)
		if i > 0:
			context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

		gut.p("--Testing insert_next with %d dummy songs in queue" % i)
		gut.p("Number of songs actually in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")
		var size_of_queue: int = context.queue.size()

		var cursor_head: QueueItem = context.get_queue_head()
		var cursor_tail: QueueItem = context.get_queue_tail()
		var cursor_middle: QueueItem = null
		if i > 2:
			cursor_middle = context.queue[
				# get a rand item between the first and the last
				context.queue.keys()[randi() % (context.queue.size() - 2) + 1]]

		var queue_positions: Array[Array] = [
			[cursor_head, "head"],
			[cursor_middle, "random middle"],
			[cursor_tail, "tail"],
		]
		for picked: Array in queue_positions:
			# set the cursor to imitate a playing song
			gut.p("Placing cursor at %s" % picked[1])
			context.cursor.item = picked[0]
			if picked[0] == null:
				gut.p("Cursor is set to null")

			gut.p("--Inserting a song from outside the queue")
			context.insert_next(RequestObj.new(out_song_to_insert, AppTool.ContextType.SONG))
			assert_eq(
				context.queue.size(),
				size_of_queue + 1,
				"Number of songs in queue does not match expected",
			)
			size_of_queue += 1

			if i > 0 and context.cursor.item != null:
				assert_eq(
					context.cursor.item.next.song.id,
					out_song_to_insert.id,
					"Next song in queue does not match inserted",
				)
			else:
				assert_eq(
					context.queue[context.queue.keys()[-1]].song.id,
					out_song_to_insert.id,
					"Last song in queue is not what was expected",
				)

			if i > 1:
				gut.p("--Inserting a song from inside the queue")
				for internal_insert: Array in queue_positions:
					if internal_insert[0] == context.cursor.item:
						gut.p("Song to insert is the same as the song at the cursor, skipping")
						continue
					gut.p("Inserting %s into next" % internal_insert[1])
					var in_item_to_insert: QueueItem = internal_insert[0]

					context.insert_next(
						RequestObj.new(
							in_item_to_insert.song,
							AppTool.ContextType.SONG,
							-1,
							in_item_to_insert.id,
						)
					)

					assert_eq(
						context.queue.size(),
						size_of_queue, #since insert_next moves from inside the queue
						"Number of songs in queue does not match expected",
					)
					assert_eq(
						context.cursor.item.next.song.id,
						in_item_to_insert.song.id,
						"Next song in queue does not match inserted",
					)
			gut.p("Done\n")

	audio_handler.free()


func test_queue_delete_item() -> void:
	var audio_handler: AudioHandler = AudioHandler.new()
	add_child(audio_handler)
	var context: PlaybackContext = audio_handler.context

	var songs: Dictionary[int, Song]

	# not adding a 0 check cause the option doesn't appear, and also
	# nothing happens
	var queue_sizes: PackedInt64Array = [1, 2, 5, 10]

	for i: int in queue_sizes:
		_make_dummy_songs(songs, i)

		audio_handler.context.set_queue_sources(songs)
		context.set_queue(RequestObj.new(songs.values()[0], AppTool.ContextType.SONG, -1))

		gut.p("--Testing remove from queue with %d dummy songs in queue" % i)
		gut.p("Number of songs actually in queue: %d" % context.queue.size())
		assert_eq(i, context.queue.size(), "Number of songs in queue does not match expected")
		var size_of_queue: int = context.queue.size()

		var cursor_head: QueueItem = context.get_queue_head()
		var cursor_tail: QueueItem = context.get_queue_tail()
		var cursor_middle: QueueItem = null
		if i > 2:
			cursor_middle = context.queue[
				# get a rand item between the first and the last
				context.queue.keys()[randi() % (context.queue.size() - 2) + 1]]

		var queue_positions: Array[Array] = [
			[cursor_head, "head"],
			[cursor_middle, "random middle"],
			[cursor_tail, "tail"],
		]
		for picked: Array in queue_positions:
			if context.queue.size() == 0:
				gut.p("Queue is empty, skipping")
				break

			if picked[0] == null:
				gut.p("%s is a null, skipping" % picked[1])
				continue
			gut.p("Removing %s from queue" % picked[1])

			context.remove_from_queue(picked[0].id)

			size_of_queue -= 1
			assert_eq(context.queue.size(), size_of_queue, "Size of queue does not match expected")

		songs.clear()
		gut.p("Done\n")

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


# to make a singular object
func _make_dummy_song() -> Song:
	var audio_dict: Dictionary = AppState.file_scanner.get_audio_dict_from_path(
		ProjectSettings.globalize_path("res://main/tests/unit/song_object/test_audio.mp3")
	)
	# Not using AppStates create song from audio dict as that would produce only one song
	# regardless of how many times its called
	var song: Song = Song.new()
	song.id = 9999 #high id for test matching
	song.path = audio_dict.get("path", "")
	song.cover_path = audio_dict.get("cover_path", "")
	song.title = audio_dict.get("title", "")
	song.artist = audio_dict.get("artist", "")
	song.album = audio_dict.get("album", "")
	song.release_year = audio_dict.get("release_year", 0)
	song.raw_length = audio_dict.get("raw_length", 0)
	return song
