class_name Library
extends RefCounted
## A management class for sets of [EntryData] resources

## Purely for aesthetics to prevent multiple same name playlists as playlists use an id system.
## The bool is a dummy value i just need a set
var _playlist_names: Dictionary[String, bool]

## All songs currently processed by the app
var _all_tracks: Dictionary[int, Song]

## All playlist currently in the app
var _playlists: Dictionary[int, Playlist]

## All albums currently in the app
var _albums: Dictionary[int, Album]

var _read_only_entries: Dictionary[AppTool.ContextType, Dictionary] = {
	AppTool.ContextType.SONG: { },
	AppTool.ContextType.PLAYLIST: { },
	AppTool.ContextType.ALBUM: { },
}

var _bus: EventBus


func set_bus(bus: EventBus) -> void:
	_bus = bus


## Returns a read_only dictionary containing all the songs in this library
func get_all_tracks() -> Dictionary[int, Song]:
	var result: Dictionary[int, Song]
	result.assign(_read_only_entries[AppTool.ContextType.SONG])
	return result


## Returns a read_only dictionary containing all the playlist in this library
func get_all_playlists() -> Dictionary[int, Playlist]:
	var result: Dictionary[int, Playlist]
	result.assign(_read_only_entries[AppTool.ContextType.PLAYLIST])
	return result


## Returns a read_only dictionary containing all the albums in this library
func get_all_albums() -> Dictionary[int, Album]:
	var result: Dictionary[int, Album]
	result.assign(_read_only_entries[AppTool.ContextType.ALBUM])
	return result


## Returns a Playlist if one with the given [param playlist_id] exists else returns
## [code]null[/code]
func get_playlist(playlist_id: int) -> Playlist:
	if not playlist_exists(playlist_id):
		return null

	return _playlists[playlist_id]


## Checks if this library has a playlist of the given id
func playlist_exists(playlist_id: int) -> bool:
	return _playlists.has(playlist_id)


## Checks if this library has an album of the given id
func album_exists(album_id: int) -> bool:
	return _albums.has(album_id)


## Checks if this library has a song of the given id
func song_exists(song_id: int) -> bool:
	return _all_tracks.has(song_id)


## Checks is a playlist with the given [param name] exists
func playlist_with_name_exists(name: String) -> bool:
	return _playlist_names.has(name)


## Checks if a playlist of the given [param playlist_id] as a song with the given [param song_id]
func playlist_has_song(song_id: int, playlist_id: int) -> bool:
	if not playlist_exists(playlist_id):
		return false

	if not _playlists[playlist_id].songs.has(song_id):
		return false

	return true


## Checks if an album of the given [param album_id] as a song with the given [param song_id]
func album_has_song(song_id: int, album_id: int) -> bool:
	if not album_exists(album_id):
		return false

	if not _albums[album_id].songs.has(song_id):
		return false

	return true


## Returns a copy of all the songs contained in the playlist of the given id if it exists, else
## returns an empty dictionary
func get_songs_from_playlist(playlist_id: int) -> Dictionary[int, Song]:
	var songs: Dictionary[int, Song]
	if not playlist_exists(playlist_id):
		return songs

	songs = _playlists[playlist_id].songs.duplicate()
	return songs


## Returns a copy of all the songs contained in the album of the given id if it exists, else
## returns an empty dictionary
func get_songs_from_album(album_id: int) -> Dictionary[int, Song]:
	var songs: Dictionary[int, Song]
	if not album_exists(album_id):
		return songs

	songs = _albums[album_id].songs.duplicate()
	return songs


## Returns a copy of all the songs contained in the library
func get_song_from_all_tracks(song_id: int) -> Song:
	if not song_exists(song_id):
		return null

	return _all_tracks[song_id]


## Adds a playlist to the library
func add_playlist(playlist: Playlist) -> void:
	_playlists[playlist.id] = playlist

	_playlist_names[playlist.title] = true

	_entry_changed(AppTool.ContextType.PLAYLIST)

## Removes a playlist from the library
func remove_playlist(playlist_id: int) -> void:
	if not playlist_exists(playlist_id):
		_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to remove a non-existent playlist")
		return
	
	_playlist_names.erase(get_playlist(playlist_id).title)
	
	_playlists.erase(playlist_id)
	
	_entry_changed(AppTool.ContextType.PLAYLIST)

## Removes all playlists in the library
func clear_playlists() -> void: 
	_playlists.clear()
	_playlist_names.clear()

## Changes a playlists title to [param new_name].
## If you want to change any other value edit the resource directly, this is special cause some
## data needs to be modified if the name changes
func edit_playlists_name(playlist_id: int, new_name: String) -> void:
	if not playlist_exists(playlist_id):
		_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to edit a non-existent playlist")
		return

	if playlist_with_name_exists(new_name):
		return

	var playlist: Playlist = get_playlist(playlist_id)

	_playlist_names.erase(playlist.title)
	playlist.title = new_name
	_playlist_names[new_name] = true


## Adds a song to the specified entry if the song and entry exist. [br]
## [enum AppTool.ContextType.SONG] == To all Tracks [br]
## [enum AppTool.ContextType.PLAYLIST] == To a Playlist [br]
## [enum AppTool.ContextType.ALBUM] == To an Album
func add_song_to_entry(song: Song, type: AppTool.ContextType, source_id: int = -1) -> void:
	if song == null:
		_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to add a non-existent song entry")
		return

	if type != AppTool.ContextType.SONG and source_id == -1:
		_log_error(ErrorLogger.LogLevel.WARN, "ID of entry to add song to not provided")
		return

	# not checking if the entry already has that entry cause its a harmless overwrite
	match type:
		AppTool.ContextType.SONG:
			_all_tracks[song.id] = song
		AppTool.ContextType.PLAYLIST:
			if not playlist_exists(source_id):
				_log_error(
					ErrorLogger.LogLevel.ERROR,
					"Attempted to add a song to a non-existent playlist",
				)
				return
			_playlists[source_id].songs[song.id] = song
		AppTool.ContextType.ALBUM:
			if not album_exists(source_id):
				_log_error(
					ErrorLogger.LogLevel.ERROR,
					"Attempted to add a song to a non-existent album",
				)
				return
			_albums[source_id].songs[song.id] = song

	_entry_changed(type)


## Removes a song from the specified entry if the song and entry exist. [br]
## [enum AppTool.ContextType.SONG] == From all Tracks [br]
## [enum AppTool.ContextType.PLAYLIST] == From a Playlist [br]
## [enum AppTool.ContextType.ALBUM] == From an Album
func remove_song_from_entry(song_id: int, type: AppTool.ContextType, source_id: int = -1) -> void:
	var song: Song

	song = get_song_from_all_tracks(song_id)

	if song == null:
		_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to remove a non-existent song")
		return

	if type != AppTool.ContextType.SONG and source_id == -1:
		_log_error(ErrorLogger.LogLevel.WARN, "ID of entry not provided to remove song from")
		return

	match type:
		AppTool.ContextType.SONG:
			_all_tracks.erase(song_id)
		AppTool.ContextType.PLAYLIST:
			if not playlist_exists(source_id):
				_log_error(
					ErrorLogger.LogLevel.ERROR,
					"Attempted to remove a song from a non-existent playlist",
				)
				return

			if not playlist_has_song(song_id, source_id):
				return

			_playlists[source_id].songs.erase(song_id)
		AppTool.ContextType.ALBUM:
			if not album_exists(source_id):
				_log_error(
					ErrorLogger.LogLevel.ERROR,
					"Attempted remove a song from a non-existent album",
				)
				return

			if not album_has_song(song_id, source_id):
				return

			_albums[source_id].songs.erase(source_id) 

	_entry_changed(type)


## Creates a brand new [Song] Resource from the given [param dict] data (Meant to be gotten from
## the MusicPlayerLib extension).[br]
## Assigns an id if the song does not already exist else returns the existing resource
func create_song_from_audio_file_dict(dict: Dictionary) -> void:
	if dict.is_empty():
		return

	var path: String = dict.get("path", "")

	var id: int = AppState.id_manager.get_id_from_path(path)
	if song_exists(id):
		return

	var song: Song = Song.new()
	song.id = id
	song.path = path
	song.cover_path = dict.get("cover_path", "")
	song.title = dict.get("title", "")
	song.artist = dict.get("artist", "")
	song.album = dict.get("album", "")
	song.release_year = dict.get("release_year", 0)
	song.raw_length = dict.get("raw_length", 0)
	add_song_to_entry(song, AppTool.ContextType.SONG)


func _entry_changed(type: AppTool.ContextType) -> void:
	var copy: Dictionary
	match type:
		AppTool.ContextType.SONG:
			copy = _all_tracks.duplicate()
		AppTool.ContextType.PLAYLIST:
			copy = _playlists.duplicate()
		AppTool.ContextType.ALBUM:
			copy = _albums.duplicate()
	copy.make_read_only()
	_read_only_entries[type] = copy


func _log_error(level: ErrorLogger.LogLevel, message: String) -> void:
	assert(_bus != null)

	_bus.data.log_error.emit(level, message)
