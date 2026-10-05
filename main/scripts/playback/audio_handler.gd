class_name AudioHandler
extends Node
## Autoload for handling music playback

## Audio Node for playing music
var audio_stream: AudioStreamPlayer

# Not put in context cause this class is the most reliable to assert what is actually
# playing
var currently_playing_song: Song

var song_info_timer: Timer

var context: PlaybackContext

## Value the [member current_song] was paused at
var music_paused_at: float

## Whether to loop on the current song or progress
var loop: bool = false


func _ready() -> void:
	audio_stream = AudioStreamPlayer.new()
	audio_stream.name = "Audio_Player"
	audio_stream.bus = &"Music"
	add_child(audio_stream)

	song_info_timer = Timer.new()
	song_info_timer.wait_time = 1
	add_child(song_info_timer)

	song_info_timer.timeout.connect(update_current_song_info)
	audio_stream.finished.connect(song_ended)

	context = PlaybackContext.new()
	context.set_cursor()

	AppEvents.audio.play_song.connect(play_song)
	AppEvents.audio.seek_song.connect(seek_song)
	AppEvents.audio.pause_play_music.connect(pause_play)
	AppEvents.audio.next_song.connect(next_in_queue)
	AppEvents.audio.prev_song.connect(prev_in_queue)
	AppEvents.audio.shuffle_queue.connect(context.shuffle_queue)
	AppEvents.audio.loop_song.connect(switch_loop)


## Plays the given song resource and updates relevant properties
func play_song(data: RequestObj) -> void:
	if data == null or data.entry_data == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to play a non-existent song",
		)
		return
	if not data.entry_data is Song:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to play entry_data type of %s" % data.entry_data.get_class(),
		)
		return
	var song: Song = data.entry_data
	if song == currently_playing_song:
		audio_stream.play()
		return

	context.set_queue(data)
	audio_stream.stop()
	var stream: AudioStream = song.get_song_stream()
	if stream == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not play audio file: \"%s\"" % song.path,
		)
		return
	audio_stream.stream = stream
	audio_stream.play()
	currently_playing_song = song
	AppEvents.ui.song_is_playing.emit(true)
	song_info_timer.start()


func update_current_song_info() -> void:
	if audio_stream.playing:
		AppEvents.ui.update_current_play_info.emit(audio_stream.get_playback_position())


## Sets the queue used in the handler. if [param rebuild] is [code]true[/code] rebuilds the queue
## regardless if its being called from the same location
## Moves the [member current_song]'s audio to [param to]
func seek_song(to: float) -> void:
	audio_stream.play(to)


## Pause's or plays the [member current_song] depending on its current pause state
func pause_play() -> void:
	if audio_stream.playing:
		music_paused_at = audio_stream.get_playback_position()
		audio_stream.stop()
		song_info_timer.paused = true
		AppEvents.ui.song_is_playing.emit(false)
	else:
		audio_stream.play(music_paused_at)
		song_info_timer.paused = false
		AppEvents.ui.song_is_playing.emit(true)


## Gets the next scheduled song in [member queue_source] and plays it
func next_in_queue() -> void:
	var next: RequestObj = context.get_next_song()
	if next == null:
		return

	AppEvents.audio.play_song.emit(next)


## Gets the previous song in [member queue_source] and plays it
func prev_in_queue() -> void:
	var prev: RequestObj = context.get_prev_song()
	if prev == null:
		return

	AppEvents.audio.play_song.emit(prev)


## Enable or disable looping on the [member current_song]
func switch_loop(on: bool) -> void:
	loop = on


## Plays the next song at the end of a songs run or simply loops the [member current_song]
## depending on [member loop]
func song_ended() -> void:
	if loop:
		play_song(context.get_current_context())
	else:
		next_in_queue()
