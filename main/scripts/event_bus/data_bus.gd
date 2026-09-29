class_name DataBus
extends RefCounted
## Event bus solely for signals that concern to/from disk data handling, storage, loading etc

## Request to save relevant app data
@warning_ignore("unused_signal")
signal save_app_data()

## Request to log error messages
@warning_ignore("unused_signal")
signal log_error(level: ErrorLogger.LogLevel, message: String)

## Request to rescan all paths in [member AppState.loaded_paths]
@warning_ignore("unused_signal")
signal rescan_loaded_paths()

## Request to save the given [Playlist] to disk
@warning_ignore("unused_signal")
signal save_playlist(playlist: Playlist)

## Request to delete the [Playlist] that tthe given [param storage_id] belongs to
@warning_ignore("unused_signal")
signal delete_playlist(storage_id: String)
