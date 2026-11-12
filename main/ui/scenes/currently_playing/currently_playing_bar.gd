class_name CurrentlyPlayingBar
extends BaseCurrentPlayingBar

## Bottom bar for displaying info on the currently playing song

@export_group("Info")
@export var song_info_btn: Button

@export_group("Controls")
@export var volume_btn: IconBtn
@export var _slider_popup: VolumeSliderPopup


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
	_slider_popup.set_bus(_bus)
	volume_btn.set_bus(_bus)
	
	song_info_btn.pressed.connect(_on_song_info_pressed)

	volume_btn.toggled.connect(toggle_slider_visibility)
	


func _on_song_info_pressed() -> void:
	if current_playing_song == null:
		return
	_bus.ui.show_entry_info_popup.emit(current_playing_song)


func toggle_slider_visibility(value: bool) -> void :
	if value:
		_slider_popup.pop_in()
	else:
		_slider_popup.pop_out()