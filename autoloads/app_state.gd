extends Node

const SAVE_FOLDER: String = "user://SaveFiles/"
const SAVE_FILE_PATH: String = "user://SaveFiles/app_data.json"
const SONG_ENTRY_SCENE: PackedScene = preload("res://main/ui/scenes/main_tab/ContainerEntry.tscn")

func _ready() -> void:
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)

var all_tracks: Array[Song]
var playlists: Array[Playlist]
