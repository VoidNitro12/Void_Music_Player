extends Node
## Autoload class to store references to data used across the system

## All songs currently processed by the app
var all_tracks: Dictionary[int, Song]

## All playlist currently in the app
var playlists: Dictionary[int, Playlist]

## All albums currently in the app
var albums: Dictionary[int, Album]

## All currently loaded directories
var loaded_paths: PackedStringArray

var app_version: String

var error_logger: ErrorLogger

var file_scanner: FileScanner

var save_system: SaveSystem

var id_manager: IdManager

## Purely for aesthetics to prevent multiple same name playlists as playlists use an id system.
## The bool is a dummy value i just need a set
var playlist_names: Dictionary[String, bool]

var session_id: String

func _ready() -> void:
	AppBootstrap.start_up()

## Creates a brand new [Song] Resource from the given [param dict] data (Meant to be gotten from 
## the MusicPlayerLib extension).[br]
## Assigns an id if the song does not already exist else returns the existing resource
func create_song_from_audio_file_dict(dict: Dictionary) -> void: 
	if dict.is_empty():
		return
	
	var path: String = dict.get("path", "")
	
	var id: int = AppState.id_manager.get_id_from_path(path)
	if AppState.all_tracks.has(id):
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
	AppState.all_tracks[id] = song
