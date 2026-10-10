class_name UiBus
extends RefCounted
## Event bus solely for signals that exist to affect ui state

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

## Requests to enable/disable mini view
@warning_ignore("unused_signal")
signal switch_to_mini_player(on: bool)

## Request to update the ui when the song queue in effect has been modified
@warning_ignore("unused_signal")
signal queue_change(queue: Dictionary[int, QueueItem], head: QueueItem, current_play: RequestObj)

## Request to [FullScreenPlayer] to hide or show the [QueueTab]
@warning_ignore("unused_signal")
signal toggle_queue_tab()

## Request to open an edit playlist popup
@warning_ignore("unused_signal")
signal edit_playlist(playlist_id: int)

## Request to open a confirmation dialog for an action
@warning_ignore("unused_signal")
signal confirm_action(action_type: AppTool.ConfirmationType, accept_func: Callable)

## Request to change the theme of the player
@warning_ignore("unused_signal")
signal change_app_theme(mode: AppTool.AppThemes)

## Request to updated the recently played list
@warning_ignore("unused_signal")
signal updated_recently_played(songs: Array[Song])
