class_name PlaybackContext
extends RefCounted

var cursor: QueueCursor

## Array of song id's for indexing
var queue: Dictionary[int, QueueItem]

var _pre_shuffled_queue: Dictionary[int, QueueItem]

var _all_tracks_queue_source: Dictionary[int, Song]

var _albums_queue_source: Dictionary[int, Album]

var _playlists_queue_source: Dictionary[int, Playlist]


func set_queue_sources(
	all_tracks: Dictionary[int, Song] = { },
	albums: Dictionary[int, Album] = { },
	playlists: Dictionary[int, Playlist] = { },
) -> void:
	_all_tracks_queue_source = all_tracks
	_albums_queue_source = albums
	_playlists_queue_source = playlists

func set_cursor() -> void:
	if cursor == null:  
		cursor = QueueCursor.new()

func set_queue(data: RequestObj) -> void:
	var context_type: AppTool.ContextType = data.source
	var source_id: int = data.source_id
	var queue_id: int = data.queue_id

	# Picking a song from outside the queue list will rebuild the queue
	if queue.has(queue_id):
		cursor.jump_to(queue_id, queue)
		return

	match context_type:
		AppTool.ContextType.SONG:
			queue = _build_queue_from_source(_all_tracks_queue_source, data)
		AppTool.ContextType.PLAYLIST:
			if source_id == -1 or _playlists_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in playlists" % source_id,
				)
				return
			queue = _build_queue_from_source(_playlists_queue_source[source_id].songs, data)
		AppTool.ContextType.ALBUM:
			if source_id == -1 or _albums_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in albums" % source_id,
				)
				return
			queue = _build_queue_from_source(_albums_queue_source[source_id].songs, data)

		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for source in AudioHandler.set_queue()",
			)
			return
	AppEvents.ui.queue_change.emit(queue)


func get_next_song() -> RequestObj:
	var to_play: Song

	cursor.advance()
	var next_item: QueueItem = cursor.item

	if next_item == null or next_item.song == null:
		return null # Default is stop playing at end. No wraps
	
	to_play = next_item.song

	var data: QueueItem = cursor.item
	return RequestObj.new(to_play, data.song_context_type, data.song_source_id, data.id)


func get_prev_song() -> RequestObj:
	var to_play: Song

	cursor.step_back()
	var prev_item: QueueItem = cursor.item

	if prev_item == null or prev_item.song == null:
		return null # Default is stop playing at beginning. No wraps

	to_play = prev_item.song

	var data: QueueItem = cursor.item
	return RequestObj.new(to_play, data.song_context_type, data.song_source_id, data.id)


func shuffle_queue(on: bool) -> void:
	if on:
		_pre_shuffled_queue = queue.duplicate()
		
		var shuffled_queue: Dictionary[int, QueueItem]
		
		# QueueItem is a resource so each need to be duplicated so has to not alter the pre
		# shuffled
		for item_id: int in queue.keys():
			var original: QueueItem = queue[item_id]
			shuffled_queue[item_id] = original.get_copy() # so i dont just get back the same ref
		
		var keys: Array[int] = queue.keys()
		keys.shuffle()
		
		for i: int in range(keys.size()): 
			var item: QueueItem = shuffled_queue[keys[i]]
			
			item.prev = null if i == 0 else shuffled_queue[keys[i-1]]
			item.next = null if i == keys.size()-1 else shuffled_queue[keys[i+1]]
		
		queue = shuffled_queue
		cursor.jump_to(cursor.item.id, shuffled_queue)
		AppEvents.ui.queue_change.emit(shuffled_queue)
	else:
		queue = _pre_shuffled_queue
		cursor.jump_to(cursor.item.id, queue)
		AppEvents.ui.queue_change.emit(queue)


func get_current_context() -> RequestObj:
	var data: QueueItem = cursor.item
	return RequestObj.new(data.song, data.song_context_type, data.song_source_id, data.id)



func _build_queue_from_source(
	source: Dictionary[int, Song],
	data: RequestObj,
) -> Dictionary[int, QueueItem]:
	var build_queue: Dictionary[int, QueueItem]

	var source_keys: Array[int] = source.keys()
	for i: int in range(source_keys.size()):
		var song: Song = source[source_keys[i]]
		var item: QueueItem

		if not build_queue.has(i):
			item = QueueItem.new()
			build_queue[i] = item
			item.id = i
		else:
			item = build_queue[i]

		item.song = song
		# Currently you cant have the same song multiple times in a playlist or album or all tracks
		# That may change but for now simply matching works to set the cursor
		if song == data.entry_data:
			cursor.item = item
		item.song_context_type = data.source
		item.song_source_id = data.source_id

		if not build_queue.has(i - 1):
			item.prev = null
		else:
			item.prev = build_queue[i - 1]

		if i + 1 > source_keys.size() - 1:
			item.next = null
		else:
			var next_item: QueueItem = QueueItem.new()
			build_queue[i + 1] = next_item
			next_item.id = i + 1

			item.next = next_item

	return build_queue


class QueueCursor:
	var item: QueueItem
	# Note using item.song as a way to check the current song will not work as next and prev
	# move the cursor to the new item and then tell audio handler to play it, hence not being
	# usefuly to check what is being played

	func advance() -> void:
		if item == null:
			return
		item = item.next


	func step_back() -> void:
		if item == null: 
			return
		item = item.prev


	func jump_to(pos: int, queue: Dictionary[int, QueueItem]) -> void:
		if not queue.has(pos):
			return

		item = queue[pos]
