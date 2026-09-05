extends Node

const SAVE_FOLDER: String = "user://app_data/"
const SAVE_FILE_PATH: String = "user://app_data/app_data.json"
const META_DATA_CACHE: String = "user://app_data/meta_data.json"
const SONG_COVER_CACHE: String = "user://app_data/cover_images/"
const CONTAINER_ENTRY_SCENE: PackedScene = preload(
	"res://main/ui/scenes/main_tab/ContainerEntry.tscn"
)

var music_player: AudioStreamPlayer
var all_tracks: Array[Song]
var playlists: Array[Playlist]


func _ready() -> void:
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)
	
	if not DirAccess.dir_exists_absolute(SONG_COVER_CACHE):
		DirAccess.make_dir_recursive_absolute(SONG_COVER_CACHE)
	
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicNode"
	add_child(music_player)
