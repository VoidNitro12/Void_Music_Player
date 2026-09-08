extends Node

const SAVE_FOLDER: String = "user://app_data/"
const SAVE_FILE_PATH: String = "user://app_data/app_data.json"
const META_DATA_CACHE: String = "user://app_data/meta_data.json"
const SONG_COVER_CACHE: String = "user://app_data/cover_images/"
const CONTAINER_ENTRY_SCENE: PackedScene = preload(
	"res://main/ui/scenes/main_tab/ContainerEntry.tscn"
)
const ENTRY_INFO_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/entry_info_popup/entry_info_popup.tscn"
)
const CONTEXT_MENU_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/context_menu/ContextMenu.tscn"
)

var all_tracks: Array[Song]
var playlists: Array[Playlist]
var albums: Array[Album]


func _ready() -> void:
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)

	if not DirAccess.dir_exists_absolute(SONG_COVER_CACHE):
		DirAccess.make_dir_recursive_absolute(SONG_COVER_CACHE)
