class_name CurrentlyPlayingBar
extends Panel

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

var current_playing_song: Song #NOTE exists already in AudioHandler, just dont wanna reach into it
var seeker_is_dragged: bool = false

func _ready() -> void:
	seeker.drag_started.connect(func()->void: seeker_is_dragged = true)
	seeker.drag_ended.connect(seek_music)
	seeker.value_changed.connect(on_seeker_value_changed)
	
	shuffle_btn.toggled.connect(on_shuffle_pressed)
	loop_btn.toggled.connect(on_loop_pressed)
	play_pause_btn.pressed.connect(on_pause_play_pressed)
	prev_btn.pressed.connect(func()-> void: AppEvents.prev_song.emit())
	next_btn.pressed.connect(func()-> void: AppEvents.next_song.emit())
	song_info_btn.pressed.connect(on_song_info_pressed)
	
	AppEvents.play_song.connect(set_currently_playing)
	AppEvents.update_current_play_info.connect(update_current_play_info)


func set_currently_playing(song: Song, _source: AppTool.MainTabSections) -> void:
	if song == null: 
		return
	
	image_rect.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	duration_label.text = AppTool.float_to_timestamp(song.raw_length)
	current_time_label.text = AppTool.float_to_timestamp(0.0)
	seeker.max_value = song.raw_length
	current_playing_song = song

func update_current_play_info(raw_length: float) -> void:  
	current_time_label.text = AppTool.float_to_timestamp(raw_length)
	if not seeker_is_dragged:
		seeker.value = raw_length

func on_seeker_value_changed(value: float) -> void: 
	if snappedf(value, 0.1) == snappedf(seeker.max_value, 0.1):
		AppEvents.song_ended.emit()

func seek_music(value_changed: bool) -> void: 
	if value_changed:
		AppEvents.seek_song.emit(seeker.value)
	seeker_is_dragged = false

func on_pause_play_pressed() -> void: 
	AppEvents.pause_play_music.emit()

func on_shuffle_pressed(toggled: bool) -> void: 
	AppEvents.shuffle_queue.emit(toggled)

func on_loop_pressed(toggled: bool) -> void: 
	AppEvents.loop_song.emit(toggled)

func on_song_info_pressed() -> void: 
	AppEvents.show_song_info_popup.emit(current_playing_song)
