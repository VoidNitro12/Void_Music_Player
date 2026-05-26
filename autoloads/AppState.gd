extends Node

const save_folder = "user://SaveFiles/"
const save_path = "user://SaveFiles/app_data.tres"

func _ready() -> void:
	Engine.max_fps = 30
	OS.low_processor_usage_mode = true
	PhysicsServer3D.set_active(false)
	PhysicsServer2D.set_active(false)
	if not DirAccess.dir_exists_absolute(save_folder):
		DirAccess.make_dir_recursive_absolute(save_folder)
	#print(ProjectSettings.globalize_path("user://"))


var auto_scan: bool = false
var rem_playback: bool = true
var current_accent:  UIScript.Accents =  UIScript.Accents.Green

var all_songs: Array
var all_playlists: Array
var song_paused_at: float

func save_app_data()-> void:
	var save = SaveData.new()
	save.auto_scan = auto_scan
	save.rem_playback = rem_playback
	save.current_accent = current_accent
	save.all_songs = all_songs
	save.all_playlists = all_playlists
	save.song_paused_at = song_paused_at
	ResourceSaver.save(save,save_path)

func load_app_data() -> SaveData:
	if not ResourceLoader.exists(save_path):
		return null
	var valid: SaveData = load(save_path)
	if not valid:
		push_error("Could not load save_file")
		return null
	return valid
