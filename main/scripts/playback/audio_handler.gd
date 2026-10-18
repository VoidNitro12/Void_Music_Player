class_name AudioHandler
extends Node
## Autoload for handling music playback

var audio: AudioEngine

# Not put in context cause this class is the most reliable to assert what is actually
# playing
## The song the handlers [AudioStreamPlayer] has set as its stream
var currently_playing_song: Song

## How many seconds till a song counts as played. Seeking the current song with [member seek]
## counts toward this
var seconds_till_played: int = 10

## Current context of the playback
var context: PlaybackContext

## Value the [member current_song] was paused at
var music_paused_at: float

## Whether to loop on the current song or progress
var loop: bool = false

var _song_played: bool = false

var _song_info_timer: Timer


func _ready() -> void:

	audio = AudioEngine.new()
	audio.set_up(AppState.error_logger)

	_song_info_timer = Timer.new()
	_song_info_timer.wait_time = 1
	add_child(_song_info_timer)

	_song_info_timer.timeout.connect(_update_current_song_info)

	context = PlaybackContext.new()
	context.set_cursor()

	Events.audio.play_song.connect(play_song)
	Events.audio.seek_song.connect(seek_song)
	Events.audio.pause_play_music.connect(pause_play)
	Events.audio.next_song.connect(next_in_queue)
	Events.audio.prev_song.connect(prev_in_queue)
	Events.audio.shuffle_queue.connect(context.shuffle_queue)
	Events.audio.loop_song.connect(switch_loop)
	Events.audio.remove_song_from_queue.connect(context.remove_from_queue)
	Events.audio.add_song_to_queue.connect(context.append_to_queue)
	Events.audio.play_next.connect(context.insert_next)


## Plays the given song resource and updates relevant properties
func play_song(data: RequestObj) -> void:
	if data == null or data.entry_data == null:
		Events.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to play a non-existent song",
		)
		return
	if not data.entry_data is Song:
		Events.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to play entry_data type of %s" % data.entry_data.get_class(),
		)
		return
	var song: Song = data.entry_data
	_song_played = false
	_song_info_timer.paused = false

	context.set_queue(data)
	# run set queue before song equal check so the same song from a different
	# location can still build the queue
	if song == currently_playing_song:
		seek_song(0.0)
		_song_info_timer.start()
		Events.ui.song_is_playing.emit(true)
		return

	var stream: AudioStream = song.get_song_stream()
	if stream == null:
		Events.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Could not play audio file: \"%s\"" % song.path,
		)
		return
	audio.play(song.path)
	currently_playing_song = song
	Events.ui.song_is_playing.emit(true)
	_song_info_timer.start()


## Seeks the currently playing song to the given position
func seek_song(to: float) -> void:
	audio.seek(to)


## Pause's or plays the [member current_song] depending on its current pause state
func pause_play() -> void:
	if audio.is_playing():
		music_paused_at = audio.get_playback_position()
		audio.pause()
		_song_info_timer.paused = true
		Events.ui.song_is_playing.emit(false)
	elif audio.is_playing() == false and audio.sound_exists():
		audio.resume()
		_song_info_timer.paused = false
		Events.ui.song_is_playing.emit(true)
	else:
		return


## Gets the next scheduled song in [member queue_source] and plays it
func next_in_queue() -> void:
	var next: RequestObj = context.get_next_song()
	if next == null:
		return

	Events.audio.play_song.emit(next)


## Gets the previous song in [member queue_source] and plays it
func prev_in_queue() -> void:
	var prev: RequestObj = context.get_prev_song()
	if prev == null:
		return

	Events.audio.play_song.emit(prev)


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


func _update_current_song_info() -> void:
	if audio.is_playing():
		Events.ui.update_current_play_info.emit(audio.get_playback_position())
		if not _song_played:
			if audio.get_playback_position() > seconds_till_played:
				Events.audio.song_played.emit(currently_playing_song)
				_song_played = true
	elif audio.audio_ended() and audio.sound_exists():
		_song_info_timer.stop()
		song_ended()
