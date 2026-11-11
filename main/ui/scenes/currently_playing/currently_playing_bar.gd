class_name CurrentlyPlayingBar
extends BaseCurrentPlayingBar

## Bottom bar for displaying info on the currently playing song

@export_group("Info")
@export var song_info_btn: Button

@export_group("Controls")
@export var volume_slider: HSlider
@export var mini_player_btn: IconBtn

var music_bus_idx: int = AudioServer.get_bus_index(&"Music")

var current_playing_song: Song  #NOTE: exists already in AudioHandler, just don't wanna reach into it


## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	if data == null:
		return
	if data.entry_data == null:
		return
	super(data)
	var song: Song = data.entry_data
	current_playing_song = song


func _configure() -> void:
	super()

	volume_slider.value_changed.connect(_change_volume)

	song_info_btn.pressed.connect(_on_song_info_pressed)

	mini_player_btn.set_bus(_bus)


func _on_song_info_pressed() -> void:
	if current_playing_song == null:
		return
	_bus.ui.show_entry_info_popup.emit(current_playing_song)


# This function is placed here because this is currently the only place a volume slider exists.
# Will be moved when settings is expanded
func _change_volume(value: float) -> void:
	_bus.audio.set_volume.emit(value)
