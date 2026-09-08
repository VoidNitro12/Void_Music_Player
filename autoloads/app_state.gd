extends Node

const SAVE_FOLDER: String = "user://app_data/"
const SAVE_FILE_PATH: String = "user://app_data/app_data.json"
const META_DATA_CACHE: String = "user://app_data/meta_data.json"
const SONG_COVER_CACHE: String = "user://app_data/cover_images/"
const PLAYLIST_COVER_CACHE: String = "user://app_data/playlist_images/"


var all_tracks: Dictionary[int, Song]
var playlists: Dictionary[int, Playlist]
var albums: Dictionary[int, Album]

var playlist_names: Dictionary[String, bool] # Purely for asthetics to prevent multiple same name 
# playlists as playlists use an id system. the bool is a dummy value i just need a set


func _ready() -> void:
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	
	for folder_path: String in [SAVE_FOLDER,SONG_COVER_CACHE,PLAYLIST_COVER_CACHE]:
		if not DirAccess.dir_exists_absolute(folder_path):
			DirAccess.make_dir_recursive_absolute(folder_path)
