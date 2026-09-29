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

# Holds a unique id for every audio file path given



func _ready() -> void:
	AppBootstrap.start_up()
