class_name PlaybackContext
extends RefCounted

## The current Song resource being played by the [member audio_stream]
var current_song: Song

## Array of song id's for indexing
var queue: Array[int]

## Source of the [member queue] containing song resource's mapped to their id's
var queue_source: Dictionary[int, Song]

## Container in [MainTab] the [member current_song] originated from
var current_context_type: AppTool.ContextType

## Id of the song's source. [code]-1[/code]  if from not playlist or album else is the id of said
## container
var current_song_source_id: int

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

func set_queue(source: AppTool.ContextType, source_id: int = -1, rebuild: bool = false) -> void:
	if current_context_type == source and current_song_source_id == source_id and not rebuild:
		return

	match source:
		AppTool.ContextType.SONG:
			queue = _all_tracks_queue_source.keys()
			queue_source = _all_tracks_queue_source.duplicate()
		AppTool.ContextType.PLAYLIST:
			if source_id == -1 or _playlists_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in playlists" % source_id,
				)
				return
			queue = _playlists_queue_source[source_id].songs.keys()
			queue_source = _playlists_queue_source[source_id].songs.duplicate()
		AppTool.ContextType.ALBUM:
			if source_id == -1 or _albums_queue_source.get(source_id) == null:
				AppEvents.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"Invalid source id of \"%d\" in albums" % source_id,
				)
				return
			queue = _albums_queue_source[source_id].songs.keys()
			queue_source = _albums_queue_source[source_id].songs.duplicate()
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for source in AudioHandler.set_queue()",
			)
			return
	current_context_type = source
	current_song_source_id = source_id
	AppEvents.ui.queue_change.emit(queue_source)

func get_next_song() -> RequestObj: 
	if current_song == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to advance queue on a null current song",
		)
		return

	if queue.is_empty():
		return

	var idx: int = queue.find(current_song.id)
	var total_idx: int = queue.size() - 1
	var to_play: Song

	if idx < total_idx:
		idx += 1
		to_play = queue_source[queue[idx]]
	else:
		to_play = queue_source[queue[0]]
	
	return RequestObj.new(to_play, current_context_type, current_song_source_id)

func get_prev_song() -> RequestObj:
	if current_song == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to go back in queue on a null current song",
		)
		return

	if queue.is_empty():
		return

	var idx: int = queue.find(current_song.id)
	var to_play: Song

	if idx > 0:
		idx -= 1
		to_play = queue_source[queue[idx]]
	else:
		to_play = queue_source[queue[-1]]
	
	return RequestObj.new(to_play, current_context_type, current_song_source_id)

func shuffle_queue(on: bool) -> void: 
	if on:
		queue.shuffle()
		var new_queue_dict: Dictionary[int, Song]

		for id: int in queue:
			new_queue_dict[id] = queue_source[id]

		AppEvents.ui.queue_change.emit(new_queue_dict)
	else:
		set_queue(current_context_type, current_song_source_id, true)

func get_current_context() -> RequestObj:
	return RequestObj.new(current_song,current_context_type,current_song_source_id)
