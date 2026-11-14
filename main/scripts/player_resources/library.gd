class_name Library
extends RefCounted

## A management class for sets of [EntryData] resources

## Purely for aesthetics to prevent multiple same name playlists as playlists use an id system.
## The bool is a dummy value i just need a set
var _playlist_names: Dictionary[String, bool]

var _album_names: Dictionary[String, bool]

## All songs currently processed by the app
var _all_tracks: Dictionary[int, Song]

## All playlist currently in the app
var _playlists: Dictionary[int, Playlist]

## All albums currently in the app
var _albums: Dictionary[int, Album]

var _read_only_entries: Dictionary[AppTool.ContextType, Dictionary] = {
	AppTool.ContextType.SONG: {},
	AppTool.ContextType.PLAYLIST: {},
	AppTool.ContextType.ALBUM: {},
}

var _bus: EventBus

var _dirty_types: Array[AppTool.ContextType] = []

func set_bus(bus: EventBus) -> void:
	_bus = bus


## Returns a copy dictionary containing all the songs in this library
func get_all_tracks() -> Dictionary[int, Song]:
	ensure_entries_current(AppTool.ContextType.SONG)
	var result: Dictionary[int, Song]
	result.assign(_read_only_entries[AppTool.ContextType.SONG])
	return result


## Returns a copy dictionary containing all the playlist in this library
func get_all_playlists() -> Dictionary[int, Playlist]:
	ensure_entries_current(AppTool.ContextType.PLAYLIST)
	var result: Dictionary[int, Playlist]
	result.assign(_read_only_entries[AppTool.ContextType.PLAYLIST])
	return result


## Returns a copy dictionary containing all the albums in this library
func get_all_albums() -> Dictionary[int, Album]:
	ensure_entries_current(AppTool.ContextType.ALBUM)
	var result: Dictionary[int, Album]
	result.assign(_read_only_entries[AppTool.ContextType.ALBUM])
	return result


## Returns a Playlist if one with the given [param playlist_id] exists else returns
## [code]null[/code]
func get_playlist(playlist_id: int) -> Playlist:
	if not playlist_exists(playlist_id):
		return null

	return _playlists[playlist_id]

func get_album(album_id: int) -> Album:
	if not album_exists(album_id):
		return null

	return _albums[album_id]


## Checks if this library has a playlist of the given id
func playlist_exists(playlist_id: int) -> bool:
	return _playlists.has(playlist_id)


## Checks if this library has an album of the given id
func album_exists(album_id: int) -> bool:
	return _albums.has(album_id)


## Checks if this library has a song of the given id in its track list.
## [b]NOTE:[/b] Does not check albums and playlists
# should probably check albums and playlists or at least specify this is for all tracks only
func song_exists(song_id: int) -> bool:
	return _all_tracks.has(song_id)


## Checks if a playlist with the given [param name] exists
func playlist_with_name_exists(name: String) -> bool:
	return _playlist_names.has(name)

## Checks if an album with the given [param name] exists
func album_with_name_exists(name: String) -> bool:
	return _album_names.has(name)


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


## Returns the song with the given id, or null if it does not exist.
func get_song_from_all_tracks(song_id: int) -> Song:
	if not song_exists(song_id):
		return null

	return _all_tracks[song_id]


## Adds a playlist to the library
func add_playlist(playlist: Playlist) -> void:
	if playlist == null:
		_log_error(
				ErrorLogger.LogLevel.ERROR,
				"Attempted to add a null playlist to the library",
		)
		return

	if playlist_exists(playlist.id):
		_playlist_names.erase(_playlists[playlist.id].title)

	_playlists[playlist.id] = playlist

	_playlist_names[playlist.title] = true

	_entry_changed(AppTool.ContextType.PLAYLIST)

## Removes a playlist from the library. [br]
## [b]NOTE:[b] This only removes the playlist from memory not from disk, if trying to delete from
## disk use [member SaveSystem.delete_playlist_file] which will automatically call this on the its
## set library value, as well as delete it from the apps tracking
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
	_entry_changed(AppTool.ContextType.PLAYLIST)

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

## Adds an album to the library
# currently private as i don't see anything else other than the scanner addition
# (which is here) needing to add a playlist
func _add_album(album: Album) -> void:
	if album == null:
		_log_error(
				ErrorLogger.LogLevel.ERROR,
				"Attempted to add a null album to the library",
		)
		return

	if album_exists(album.id):
		_album_names.erase(_albums[album.id].title)

	_albums[album.id] = album

	_album_names[album.title] = true

	_entry_changed(AppTool.ContextType.ALBUM)

## Adds a song to the specified entry if the song and entry exist. [br]
## [enum AppTool.ContextType.SONG] == To all Tracks [br]
## [enum AppTool.ContextType.PLAYLIST] == To a Playlist [br]
## [enum AppTool.ContextType.ALBUM] == To an Album
func add_song_to_entry(song: Song, type: AppTool.ContextType, source_id: int=-1) -> void:
	if song == null:
		_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to add a non-existent song entry")
		return

	if type != AppTool.ContextType.SONG and source_id == -1:
		_log_error(ErrorLogger.LogLevel.WARN, "ID of entry to add song to not provided")
		return

	# not checking if the entry already has that song cause its a harmless overwrite
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
func remove_song_from_entry(song_id: int, type: AppTool.ContextType, source_id: int=-1) -> void:

	if type != AppTool.ContextType.SONG and source_id == -1:
		_log_error(ErrorLogger.LogLevel.WARN, "ID of entry not provided to remove song from")
		return

	match type:
		AppTool.ContextType.SONG:
			if not song_exists(song_id):
				_log_error(ErrorLogger.LogLevel.ERROR, "Attempted to remove a non-existent song")
				return

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

			_albums[source_id].songs.erase(song_id)

	_entry_changed(type)


## Creates a [Song] (and [Album], if needed) resource from the given audio-file dictionary.
## (Meant to be gotten from the MusicPlayerLib extension).
func create_song_from_audio_file_dict(dict: Dictionary) -> void:
	if dict.is_empty():
		return

	var path: String = dict.get("path", "")

	var id: int = AppState.id_manager.get_id_from_path(path)
	var song: Song
	if not song_exists(id):
		song = Song.new()
		song.id = id
		song.path = path
		song.cover_path = dict.get("cover_path", "")
		song.title = dict.get("title", "")
		song.artist = dict.get("artist", "")
		song.album = dict.get("album", "")
		song.release_year = dict.get("release_year", 0)
		song.raw_length = dict.get("raw_length", 0)
		add_song_to_entry(song, AppTool.ContextType.SONG)
	else:
		song = get_song_from_all_tracks(id)

	if not song.album.is_empty():
		var album_id: int = AppState.id_manager.get_id_for_album(song.album)
		if not album_exists(album_id):
			var album: Album = Album.new()
			album.id = album_id
			album.title = song.album
			album.artist = song.artist
			album.release_year = song.release_year
			album.cover_path = song.cover_path
			_add_album(album)
		add_song_to_entry(song, AppTool.ContextType.ALBUM, album_id)


func _entry_changed(type: AppTool.ContextType) -> void:
	if not _dirty_types.has(type):
		_dirty_types.append(type)

func ensure_entries_current(type: AppTool.ContextType) -> void:
	if not  _dirty_types.has(type):
		return

	var copy: Dictionary
	match type:
		AppTool.ContextType.SONG:
			copy = _all_tracks.duplicate()
		AppTool.ContextType.PLAYLIST:
			copy = _playlists.duplicate()
		AppTool.ContextType.ALBUM:
			copy = _albums.duplicate()
		_:
			_log_error(
			ErrorLogger.LogLevel.ERROR,
			"Unexpected ContextType: %s" % type,
			)
			return
	copy.make_read_only()
	_read_only_entries[type] = copy
	_dirty_types.erase(type)


func _log_error(level: ErrorLogger.LogLevel, message: String) -> void:
	assert(_bus != null)

	_bus.data.log_error.emit(level, message)
