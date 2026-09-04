class_name CurrentlyPlayingBar
extends Panel

@export_group("Info")
@export var image_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label

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


func _ready() -> void:
	pass


func set_currently_playing(song: Song) -> void:
	if song == null: 
		return
	
	image_rect.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	duration_label.text = AppTool.float_to_timestamp(song.raw_length)
	current_time_label.text = AppTool.float_to_timestamp(0.0)
