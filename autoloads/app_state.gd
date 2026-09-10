extends Node
## Autoload class to store references to data used across the system

## Path to the general save folder of the app
const SAVE_FOLDER: String = "user://app_data/"

## Path to the specific general use save json
const SAVE_FILE_PATH: String = "user://app_data/app_data.json"

const ID_TRACKER_SAVE_PATH: String = "user://app_data/id_tracker.json"

## Path to the json file containing metadata for all processed songs
const META_DATA_CACHE: String = "user://app_data/meta_data.json"

## Path to the folder containing cover images for all processed songs
const SONG_COVER_CACHE: String = "user://app_data/cover_images/"

## Path to the folder containing cover images for all created playlists
const PLAYLIST_COVER_CACHE: String = "user://app_data/playlist_images/"

## All songs currently processed by the app
var all_tracks: Dictionary[int, Song]

## All playlist currently in the app
var playlists: Dictionary[int, Playlist]

## All albums currently in the app
var albums: Dictionary[int, Album]

## Purely for aesthetics to prevent multiple same name playlists as playlists use an id system.
## The bool is a dummy value i just need a set
var playlist_names: Dictionary[String, bool]

# Holds a unique id for every path given
var _id_tracker: Dictionary[String, int]


func _ready() -> void:
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)

	for folder_path: String in [SAVE_FOLDER, SONG_COVER_CACHE, PLAYLIST_COVER_CACHE]:
		if not DirAccess.dir_exists_absolute(folder_path):
			DirAccess.make_dir_recursive_absolute(folder_path)
	
	SaveSystem.load_data()
	_id_tracker = SaveSystem.load_id_tracker()
	AppEvents.save_app_data.connect(SaveSystem.save_data)


## Returns the id for the given [param path] if exists, else makes a new unique one
func get_id_from_path(path: String) -> int:
	var id: int
	if _id_tracker.has(path):
		id = _id_tracker[path]
	else:
		id = _id_tracker.size()
		_id_tracker[path] = id
		SaveSystem.save_id_tracker(_id_tracker)
	return id
