extends Node
## Event bus for cross system communication

# A signal needing RequestObj means it's receivers need context
# While just EntryData means they don't require it
## Signal request to play song resource
@warning_ignore("unused_signal")
signal play_song(data: RequestObj)

## Signal request to seek to a particular position on the current song
@warning_ignore("unused_signal")
signal seek_song(to: float)

## Indicates a change in the play duration of [member AudioHandler.current_song]
@warning_ignore("unused_signal")
signal update_current_play_info(raw_length: float)

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

## Indicates when a song has ended its duration.
@warning_ignore("unused_signal")
signal song_ended()

## Request to enable or disable a shuffled on the current [member AudioHandler.queue]
@warning_ignore("unused_signal")
signal shuffle_queue(on: bool)

## Request to enable/disable lo0ping on the current [member AudioHandler.current_song]
@warning_ignore("unused_signal")
signal loop_song(on: bool)

## Request to refresh [member AppState.all_track]
@warning_ignore("unused_signal")
signal refresh_all_tracks()

## Request to refresh [member AppState.album]
@warning_ignore("unused_signal")
signal refresh_albums()

## Request to refresh [member AppState.playlists]
@warning_ignore("unused_signal")
signal refresh_playlist()

## Request to open the contents of an album or playlist on the [MainTab]
@warning_ignore("unused_signal")
signal open_packed_entry(data: EntryData)

## Request to create an info popup for an entry data's details
@warning_ignore("unused_signal")
signal show_entry_info_popup(data: RequestObj)

## Request to close an info popup for an entry data's details
@warning_ignore("unused_signal")
signal close_entry_info_popup(data: EntryData)

## Request to popup a context menu at the mouse's current position
@warning_ignore("unused_signal")
signal show_context_menu(data: RequestObj)

## Request to block input and spawn a [LoadingPopup]
@warning_ignore("unused_signal")
signal start_loading_wait()

## Request to end the current [LoadingPopup]
@warning_ignore("unused_signal")
signal end_loading_wait()

## Request to save relevant app data
@warning_ignore("unused_signal")
signal save_app_data()

## Request to log error messages
@warning_ignore("unused_signal")
signal log_error(level: AppTool.LogLevels, message: String)
