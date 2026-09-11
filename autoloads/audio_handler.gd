extends Node
## Autoload for handling music playback

## Audio Node for playing music
var audio_stream: AudioStreamPlayer

## The current Song resource being played by the [member audio_stream]
var current_song: Song

## Array of song id's for indexing
var queue: Array[int]

## Source of the [member queue] containing song resource's mapped to their id's
var queue_source: Dictionary[int, Song]

## Container in [MainTab] the [member current_song] originated from
var current_queue_source: AppTool.MainTabSections

## Id of the song's source. [code]-1[/code]  if from not playlist or album else is the id of said
## container
var current_queue_id: int

## Value the [member current_song] was paused at
var music_paused_at: float

## Whether to loop on the current song or progress
var loop: bool = false


func _ready() -> void:
	audio_stream = AudioStreamPlayer.new()
	audio_stream.name = "Audio_Player"
	add_child(audio_stream)

	AppEvents.play_song.connect(play_song)
	AppEvents.seek_song.connect(seek_song)
	AppEvents.pause_play_music.connect(pause_play)
	AppEvents.next_song.connect(next_in_queue)
	AppEvents.prev_song.connect(prev_in_queue)
	AppEvents.shuffle_queue.connect(switch_shuffle)
	AppEvents.song_ended.connect(song_ended)


func _process(_delta: float) -> void:
	if audio_stream.playing:
		AppEvents.update_current_play_info.emit(audio_stream.get_playback_position())


## Plays the given song resource and updates relevant properties
func play_song(data: RequestObj) -> void:
	if data == null:
		return
	if not data.entry_data is Song:
		return
	var song: Song = data.entry_data

	set_queue(data.source, data.source_id)
	audio_stream.stop()
	var stream: AudioStream = song.get_song_stream()
	if stream == null:
		AppEvents.log_error.emit(
			AppTool.LogLevels.ERROR,
			"Could not play audio file: \"%s\"" % song.path,
		)
		return
	audio_stream.stream = stream
	audio_stream.play()
	current_song = song


## Sets the queue used in the handler. if [param rebuild] is [code]true[/code] rebuilds the queue
## regardless if its being called from the same location
func set_queue(source: AppTool.MainTabSections, source_id: int = -1, rebuild: bool = false) -> void:
	if current_queue_source == source and not rebuild:
		return

	match source:
		AppTool.MainTabSections.ALL_SONGS:
			queue = AppState.all_tracks.keys()
			queue_source = AppState.all_tracks.duplicate()
		AppTool.MainTabSections.PLAYLISTS:
			if source_id == -1 or AppState.playlists.get(source_id) == null:
				AppEvents.log_error.emit(
					AppTool.LogLevels.WARN,
					"Invalid source id of \"%d\" in playlists" % source_id,
				)
				return
			queue = AppState.playlists[source_id].songs.keys()
			queue_source = AppState.playlists[source_id].songs.duplicate()
		AppTool.MainTabSections.ALBUMS:
			if source_id == -1 or AppState.albums.get(source_id) == null:
				AppEvents.log_error.emit(
					AppTool.LogLevels.WARN,
					"Invalid source id of \"%d\" in albums" % source_id,
				)
				return
			queue = AppState.albums[source_id].songs.keys()
			queue_source = AppState.albums[source_id].songs.duplicate()
		_:
			AppEvents.log_error.emit(
				AppTool.LogLevels.ERROR,
				"Invalid Option for source in AudioHandler.set_queue()",
			)
			return
	current_queue_source = source
	current_queue_id = source


## Moves the [member current_song]'s audio to [param to]
func seek_song(to: float) -> void:
	audio_stream.play(to)


## Pause's or plays the [member current_song] depending on its current pause state
func pause_play() -> void:
	if audio_stream.playing:
		audio_stream.stop()
		music_paused_at = audio_stream.get_playback_position()
	else:
		audio_stream.play(music_paused_at)


## Gets the next scheduled song in [member queue_source] and plays it
func next_in_queue() -> void:
	if queue.is_empty():
		return

	var idx: int = current_song.id
	var total_idx: int = queue.size() - 1
	var to_play: Song

	if idx < total_idx:
		idx += 1
		to_play = queue_source[idx]
	else:
		to_play = queue_source[queue[0]]

	AppEvents.play_song.emit(RequestObj.new(to_play, current_queue_source, current_queue_id))


## Gets the previous song in [member queue_source] and plays it
func prev_in_queue() -> void:
	if queue.is_empty():
		return

	var idx: int = current_song.id
	var to_play: Song

	if idx > 0:
		idx -= 1
		to_play = queue_source[idx]
	else:
		to_play = queue_source[queue[-1]]

	AppEvents.play_song.emit(RequestObj.new(to_play, current_queue_source, current_queue_id))


## Shuffles or reverses a shuffle on [member queue]
func switch_shuffle(on: bool) -> void:
	if on:
		queue.shuffle()
	else:
		set_queue(current_queue_source, current_queue_id, true)


## Enable or disable looping on the [member current_song]
func switch_loop(on: bool) -> void:
	loop = on


## Plays the next song at the end of a songs run or simple loops the [member current_song]
## depending on [member loop]
func song_ended() -> void:
	if loop:
		play_song(RequestObj.new(current_song, current_queue_source, current_queue_id))
	else:
		next_in_queue()
