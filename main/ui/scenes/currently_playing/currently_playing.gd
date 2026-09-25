class_name CurrentlyPlayingBar
extends BaseCurrentPlayingBar
## Bottom bar for displaying info on the currently playing song

@export_group("Info")
@export var song_info_btn: Button

@export_group("Controls")
@export var volume_slider: HSlider
@export var mini_player_btn: Button

@export_subgroup("Seeker")
@export var current_time_label: Label
@export var duration_label: Label



var current_playing_song: Song #NOTE: exists already in AudioHandler, just don't wanna reach into it


func _ready() -> void:
	super()
	
	volume_slider.value_changed.connect(_change_volume) 

	mini_player_btn.pressed.connect(
		func() -> void:
			AppEvents.switch_to_mini_player.emit(true),
	)
	
	song_info_btn.pressed.connect(_on_song_info_pressed)


## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	super(data)
	var song: Song = data.entry_data
	duration_label.text = AppTool.int_to_timestamp(song.raw_length)
	current_time_label.text = AppTool.int_to_timestamp(0.0)
	current_playing_song = song 

func _update_current_play_info(raw_length: float) -> void:
	current_time_label.text = AppTool.int_to_timestamp(raw_length)
	if not _seeker_is_dragged:
		seeker.value = raw_length

func _on_song_info_pressed() -> void:
	if current_playing_song == null:
		return
	AppEvents.show_entry_info_popup.emit(current_playing_song)

# This function is placed here because this is currently the only place a volume slider exists.
# Will be moved when settings is expanded
func _change_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(music_bus_idx, value)
