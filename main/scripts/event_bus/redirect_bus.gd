class_name RedirectBus
extends RefCounted
## Basically a sub ui bus that exists to handle redirects to other sections of the app.
## instead of being a direct signal its a bus cause some redirects (most)
## would require the equivalent of multiple clicks

## Jumps the page to the [SettingsLibrarySection] of the [SettingsTab]
@warning_ignore("unused_signal")
signal to_file_scanning()

## Jumps the page to the [MainTab] and opens a [PlaylistOptionsPopup]
@warning_ignore("unused_signal")
signal to_playlist_creation()

## Jumps the page to the [MainTab] and opens a [PlaylistOptionsPopup] in edit mode for the current
## playlist
@warning_ignore("unused_signal")
signal to_playlist_edit_songs()
