extends Node

var audio_stream: AudioStreamPlayer

var current_song: Song
var queue: Array[Song]
var current_queue_source: AppTool.MainTabSections
var current_queue_id: int
var music_paused_at: float
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


func play_song(song: Song, source: AppTool.MainTabSections, source_id: int = -1) -> void:
	if song == null:
		return
	set_queue(source, source_id)
	audio_stream.stop()
	var stream: AudioStream = song.get_song_stream()
	if not stream:
		push_error("Error playing audio file: \"%s\"" % song.path)
		return
	audio_stream.stream = stream
	audio_stream.play()
	current_song = song


func set_queue(source: AppTool.MainTabSections, source_id: int = -1, rebuild: bool = false) -> void:
	if current_queue_source == source and not rebuild:
		return

	match source:
		AppTool.MainTabSections.ALL_SONGS:
			queue = AppState.all_tracks.duplicate()
		AppTool.MainTabSections.PLAYLISTS:
			if source_id == -1 or AppState.playlists.get(source_id) == null:
				push_error("Invalid source id of \"%d\" in playlists" % source_id)
				return

			queue = AppState.playlists[source_id].songs.duplicate()
		AppTool.MainTabSections.ALBUMS:
			#TODO
			pass
		_:
			push_error("Invalid Option")
			return
	current_queue_source = source
	current_queue_id = source


func seek_song(to: float) -> void:
	audio_stream.play(to)


func pause_play() -> void:
	if audio_stream.playing:
		audio_stream.stop()
		music_paused_at = audio_stream.get_playback_position()
	else:
		audio_stream.play(music_paused_at)


func next_in_queue() -> void:
	var idx: int = queue.find(current_song)
	var total_idx: int = queue.size() - 1
	var to_play: Song

	if idx < total_idx:
		idx += 1
		to_play = queue[idx]
	else:
		to_play = queue[0]

	play_song(to_play, current_queue_source, current_queue_id)


func prev_in_queue() -> void:
	var idx: int = queue.find(current_song)
	var to_play: Song

	if idx > 0:
		idx -= 1
		to_play = queue[idx]
	else:
		to_play = queue[-1]

	play_song(to_play, current_queue_source, current_queue_id)


func switch_shuffle(on: bool) -> void:
	if on:
		queue.shuffle()
	else:
		set_queue(current_queue_source, current_queue_id, true)

func switch_loop(on: bool) -> void:
	loop = on

func song_ended() -> void: 
	if loop:
		play_song(current_song,current_queue_source)
	else:
		next_in_queue()
