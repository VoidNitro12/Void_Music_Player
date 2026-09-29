class_name QueueEntry
extends Control

@export var image: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var action_btn: Button


func _ready() -> void:
	pass # Replace with function body.

func set_data(song: Song, btn_group: ButtonGroup = null) -> void:
	if song == null:
		return
	
	image.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	
	action_btn.button_group = btn_group
