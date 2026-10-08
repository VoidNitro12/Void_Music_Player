class_name PlaybackContext
extends RefCounted

var cursor: QueueCursor

## Array of song id's for indexing
var queue: Dictionary[int, QueueItem]

# Head of the current queue linked list
var _head: QueueItem

# Tail of the current queue linked list
var _tail: QueueItem

# Id tracker for queue item ids to avoid collisions or overwrites
var _item_ids: int = 0

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
			_break_queue(queue) # destroy the old queue
			queue = _build_queue_from_source(_all_tracks_queue_source, data)
		AppTool.ContextType.PLAYLIST:
			if source_id == -1 or _playlists_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in playlists" % source_id,
				)
				return
			_break_queue(queue) # destroy the old queue
			queue = _build_queue_from_source(_playlists_queue_source[source_id].songs, data)
		AppTool.ContextType.ALBUM:
			if source_id == -1 or _albums_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in albums" % source_id,
				)
				return
			_break_queue(queue) # destroy the old queue
			queue = _build_queue_from_source(_albums_queue_source[source_id].songs, data)

		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for source in AudioHandler.set_queue()",
			)
			return
	_break_queue(_pre_shuffled_queue) # destroy shuffle snapshot
	_rebuild_queue_tab(queue)


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

		# QueueItem is a RefCounted so each need to be duplicated so has to not alter the pre
		# shuffled
		for item_id: int in queue.keys():
			var original: QueueItem = queue[item_id]
			shuffled_queue[item_id] = original.get_copy() # so i dont just get back the same ref

		var keys: Array[int] = queue.keys()
		keys.shuffle()

		for i: int in range(keys.size()):
			var item: QueueItem = shuffled_queue[keys[i]]

			item.prev = null if i == 0 else shuffled_queue[keys[i - 1]]
			item.next = null if i == keys.size() - 1 else shuffled_queue[keys[i + 1]]

		queue = shuffled_queue
		cursor.jump_to(cursor.item.id, shuffled_queue)
		_rebuild_queue_tab(shuffled_queue)
	else:
		queue = _pre_shuffled_queue
		cursor.jump_to(cursor.item.id, queue)
		_rebuild_queue_tab(queue)


## Removes the [QueueItem] belonging to the id from the queue if its in it
func remove_from_queue(id: int) -> void:
	if not queue.has(id):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Attempted to remove a non existent item from the queue",
		)
		return

	var item: QueueItem = queue[id]

	if item == _head:
		_head = item.next
		item.next.prev = null
		item.next = null
	elif item == _tail:
		_tail = item.prev
		item.prev.next = null
		item.prev = null
	else:
		item.prev.next = item.next
		item.next.prev = item.prev

		item.next = null
		item.prev = null

	# If you remove the item the cursor is pointing at, the cursor will keep a reference to it
	# alive as its still playing. once the cursor is then moved, backtracking
	# will point to the items prev and forwarding to its next (re-link)
	queue.erase(id)

	_rebuild_queue_tab(queue)


## Adds the song packaged in [param data] to the end of thequeue regardless of it its in
## the queue or not
func append_to_queue(data: RequestObj) -> void:
	if queue.is_empty():
		AppEvents.audio.play_song.emit(data)
		return

	var item: QueueItem = _make_new_queue_item(data)
	queue[item.id] = item

	_tail.next = item
	item.prev = _tail

	_tail = item

	_rebuild_queue_tab(queue)


## Adds the song packaged in [param data] to the queue after the current cursor item. Creates a
## new queue item if its not in the queue else moves an existing one
func insert_next(data: RequestObj) -> void:
	if queue.is_empty():
		AppEvents.audio.play_song.emit(data)
		return

	var item: QueueItem

	if not queue.has(data.queue_id):
		item = _make_new_queue_item(data)
		queue[item.id] = item
	else:
		item = queue[data.queue_id]

		if item == cursor.item:
			# dont alter if its the current song from within the queue
			return

		# Link former neighbours
		if item == _head:
			item.next.prev = null
			_head = item.next
		elif item == _tail:
			item.prev.next = null
			_tail = item.prev
		else:
			item.prev.next = item.next
			item.next.prev = item.prev

	# Link the item to be after the current cursor item
	if cursor.item == _tail:
		item.prev = cursor.item
		item.next = null
		cursor.item.next = item
		_tail = item
	elif cursor.item == _head:
		item.prev = null
		item.next = cursor.item
		cursor.item.prev = item
		_head = item
	else:
		item.prev = cursor.item
		item.next = cursor.item.next

		cursor.item.next.prev = item

		cursor.item.next = item

	_rebuild_queue_tab(queue)


func get_current_context() -> RequestObj:
	if cursor == null or cursor.item == null:
		return null

	var data: QueueItem = cursor.item
	return RequestObj.new(data.song, data.song_context_type, data.song_source_id, data.id)


func is_cursor_on_item(queue_id: int) -> bool:
	if not queue.has(queue_id):
		return false

	if cursor.item == queue[queue_id]:
		return true

	return false


func _build_queue_from_source(
	source: Dictionary[int, Song],
	data: RequestObj,
) -> Dictionary[int, QueueItem]:
	var build_queue: Dictionary[int, QueueItem]

	var source_keys: Array[int] = source.keys()
	_item_ids = 0
	for i: int in range(source_keys.size()):
		var song: Song = source[source_keys[i]]
		var item: QueueItem

		if i == 0:
			item = QueueItem.new()
			build_queue[i] = item
			item.id = i
			_head = item
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

		if i == source_keys.size() - 1:
			_tail = item

		if i + 1 > source_keys.size() - 1:
			item.next = null
		else:
			var next_item: QueueItem = QueueItem.new()
			build_queue[i + 1] = next_item
			next_item.id = i + 1

			item.next = next_item

		_item_ids += 1

	return build_queue


# Since QueueItem is a refcounted and the double linked list is cyclic by nature, this
# just clears everything
func _break_queue(old: Dictionary[int, QueueItem]) -> void:
	for i: QueueItem in old.values():
		i.next = null
		i.prev = null


func _make_new_queue_item(data: RequestObj) -> QueueItem:
	var item: QueueItem
	item = QueueItem.new()
	item.song = data.entry_data
	item.song_context_type = data.source
	item.song_source_id = data.source_id
	item.id = _item_ids
	_item_ids += 1
	return item


# this particular signal has changed like 5 times and its easy to forget to change parameters
# everywhere on signal calls
func _rebuild_queue_tab(new_queue: Dictionary[int, QueueItem]) -> void:
	AppEvents.ui.queue_change.emit(new_queue, _head, get_current_context())


class QueueCursor:
	var item: QueueItem


	# Note using item.song as a way to check the current song will not work for audio handlers
	# same song check as next and prev move the cursor to the new item and then tell audio handler
	# to play it, hence not being usefuly to check what is being played in that instance, for other
	# cases it works as a check
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
