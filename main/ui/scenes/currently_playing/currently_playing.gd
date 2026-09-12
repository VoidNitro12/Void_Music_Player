class_name CurrentlyPlayingBar
extends Panel
## Bottom bar for displaying info on the currently playing song

const PLAY_ICON: CompressedTexture2D = preload("res://assets/icons/play_btn.svg")
const PAUSE_ICON: CompressedTexture2D = preload("res://assets/icons/pause_btn.svg")

@export_group("Info")
@export var image_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var song_info_btn: Button

@export_group("Controls")
@export var shuffle_btn: Button
@export var prev_btn: Button
@export var play_pause_btn: Button
@export var next_btn: Button
@export var loop_btn: Button
@export var volume_slider: HSlider

@export_subgroup("Seeker")
@export var current_time_label: Label
@export var seeker: HSlider
@export var duration_label: Label

var current_playing_song: Song #NOTE: exists already in AudioHandler, just don't wanna reach into it

var _seeker_is_dragged: bool = false


func _ready() -> void:
	seeker.drag_started.connect(
		func() -> void:
			_seeker_is_dragged = true,
	)
	seeker.drag_ended.connect(_seek_music)
	seeker.value_changed.connect(_on_seeker_value_changed)

	shuffle_btn.toggled.connect(_on_shuffle_pressed)
	loop_btn.toggled.connect(_on_loop_pressed)
	play_pause_btn.pressed.connect(_on_pause_play_pressed)
	prev_btn.pressed.connect(
		func() -> void:
			AppEvents.prev_song.emit(),
	)
	next_btn.pressed.connect(
		func() -> void:
			AppEvents.next_song.emit(),
	)
	song_info_btn.pressed.connect(_on_song_info_pressed)

	AppEvents.play_song.connect(set_currently_playing)
	AppEvents.update_current_play_info.connect(_update_current_play_info)
	AppEvents.song_is_playing.connect(change_pause_play_icon)

## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	if data == null:
		return
	if not data.entry_data is Song:
		return
	var song: Song = data.entry_data

	image_rect.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	duration_label.text = AppTool.float_to_timestamp(song.raw_length)
	current_time_label.text = AppTool.float_to_timestamp(0.0)
	seeker.max_value = song.raw_length
	current_playing_song = song


func _update_current_play_info(raw_length: float) -> void:
	current_time_label.text = AppTool.float_to_timestamp(raw_length)
	if not _seeker_is_dragged:
		seeker.value = raw_length

func change_pause_play_icon(on: bool) -> void: 
	if on: 
		play_pause_btn.icon = PAUSE_ICON
	else: 
		play_pause_btn.icon = PLAY_ICON

func _on_seeker_value_changed(value: float) -> void:
	if snappedf(value, 0.1) == snappedf(seeker.max_value, 0.1):
		AppEvents.song_ended.emit()
		seeker.value = 0.0


func _seek_music(value_changed: bool) -> void:
	if value_changed:
		AppEvents.seek_song.emit(seeker.value)
	_seeker_is_dragged = false


func _on_pause_play_pressed() -> void:
	AppEvents.pause_play_music.emit()


func _on_shuffle_pressed(toggled: bool) -> void:
	AppEvents.shuffle_queue.emit(toggled)


func _on_loop_pressed(toggled: bool) -> void:
	AppEvents.loop_song.emit(toggled)


func _on_song_info_pressed() -> void:
	if current_playing_song == null: 
		return
	AppEvents.show_entry_info_popup.emit(current_playing_song)
