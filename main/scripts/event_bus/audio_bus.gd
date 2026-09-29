class_name AudioBus
extends RefCounted
## Event bus solely for signals that affect audio playback

## Signal request to play song resource
@warning_ignore("unused_signal")
signal play_song(data: RequestObj)

## Signal request to seek to a particular position on the current song
@warning_ignore("unused_signal")
signal seek_song(to: float)

## Request to pause/play [member AudioHandler.current_song]
## depending on its current play state
@warning_ignore("unused_signal")
signal pause_play_music()

## Request to walk forward 1 step on the current [member AudioHandler.queue]
@warning_ignore("unused_signal")
signal next_song()

## Request to walk back 1 step on the current [member AudioHandler.queue]
@warning_ignore("unused_signal")
signal prev_song()

## Request to enable or disable a shuffled on the current [member AudioHandler.queue]
@warning_ignore("unused_signal")
signal shuffle_queue(on: bool)

## Request to enable/disable looping on the current [member AudioHandler.current_song]
@warning_ignore("unused_signal")
signal loop_song(on: bool)
