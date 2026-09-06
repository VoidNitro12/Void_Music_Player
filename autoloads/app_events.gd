extends Node

## Signal request to play song resourse
@warning_ignore("unused_signal")
signal play_song(data: RequestObj)

## Signal request to seek to a particular possition on the current song 
@warning_ignore("unused_signal")
signal seek_song(to: float)

## Indicates a change in the play duration of the current [AudioHandler.current_song] 
@warning_ignore("unused_signal")
signal update_current_play_info(raw_length: float)

## Signal request to pause/play the current [property AudioHandler.current_song] 
## depending on its current play state
@warning_ignore("unused_signal")
signal pause_play_music()

## Signal request to walk forward 1 step on the current [property AudioHandler.queue]
@warning_ignore("unused_signal")
signal next_song()

## Signal request to walk back 1 step on the current [property AudioHandler.queue]
@warning_ignore("unused_signal")
signal prev_song()

## Indicates when a song has ended its duration. i.e seeked to the end
@warning_ignore("unused_signal")
signal song_ended()

## Signal request to enable or fisable a shuffled on thr current [property AudioHanler.queue] list
@warning_ignore("unused_signal")
signal shuffle_queue(on: bool)

@warning_ignore("unused_signal")
signal loop_song(on: bool)

## Fired when [property AppState.all_tracks] has been populated
@warning_ignore("unused_signal")
signal all_tracks_set()

@warning_ignore("unused_signal")
signal show_song_info_popup(song: Song)

@warning_ignore("unused_signal")
signal close_song_info_popup(song: Song)

@warning_ignore("unused_signal")
signal show_context_menu(data: RequestObj)
