extends Node
## Event bus for cross system communication

var audio: AudioBus

var ui: UiBus

# A signal needing RequestObj means it's receivers need context
# While just EntryData means they don't require it





## Request to save relevant app data
@warning_ignore("unused_signal")
signal save_app_data()

## Request to log error messages
@warning_ignore("unused_signal")
signal log_error(level: ErrorLogger.LogLevel, message: String)

## Request to rescan all paths in [member AppState.loaded_paths]
@warning_ignore("unused_signal")
signal rescan_loaded_paths()



@warning_ignore("unused_signal")
signal save_playlist(playlist: Playlist)

@warning_ignore("unused_signal")
signal delete_playlist(storage_id: String)
