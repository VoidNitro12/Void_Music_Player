class_name MiniEntry
extends Control

@export var image: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var action_btn: Button

var data_obj: RequestObj


func _ready() -> void:
	action_btn.gui_input.connect(_on_gui_input)
	action_btn.pressed.connect(_on_pressed)
	action_btn.toggled.connect(_handle_theme_labels)


func set_data(data: RequestObj, btn_group: ButtonGroup = null) -> void:
	var song: Song = data.entry_data
	if song == null:
		return

	image.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	
	data_obj = data

	action_btn.button_group = btn_group


func _on_pressed() -> void:
	AppEvents.audio.play_song.emit(data_obj)


# The theme's don't handle selected btns well since their text is actually 2 separate labels
# and not the buttons text hence this function to handle them specially
func _handle_theme_labels(selected: bool) -> void:
	if selected:
		for label: Label in [artist_label, title_label]:
			label.add_theme_color_override(
				"font_color",
				action_btn.get_theme_color("font_pressed_color", "Button"),
			)
	else:
		for label: Label in [artist_label, title_label]:
			label.remove_theme_color_override("font_color")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				AppEvents.ui.show_context_menu.emit(data_obj)
			_:
				return
