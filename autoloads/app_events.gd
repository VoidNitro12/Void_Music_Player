extends Node
## Event bus for cross system communication

var audio: AudioBus

# A signal needing RequestObj means it's receivers need context
# While just EntryData means they don't require it



## Indicates a change in the play duration of [member AudioHandler.current_song]
@warning_ignore("unused_signal")
signal update_current_play_info(raw_length: float)

## Notifying signal sent from [AudioHandler] based on if a song is being played or not
@warning_ignore("unused_signal")
signal song_is_playing(on: bool)

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
signal show_entry_info_popup(data: EntryData)

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
signal log_error(level: ErrorLogger.LogLevel, message: String)

## Request to rescan all paths in [member AppState.loaded_paths]
@warning_ignore("unused_signal")
signal rescan_loaded_paths()

## Requests to enable/disable mini view
@warning_ignore("unused_signal")
signal switch_to_mini_player(on: bool)

## Request to update the ui when the song queue in effect has been modified
@warning_ignore("unused_signal")
signal queue_change(queue: Dictionary[int, Song])

@warning_ignore("unused_signal")
signal save_playlist(playlist: Playlist)

@warning_ignore("unused_signal")
signal delete_playlist(storage_id: String)
