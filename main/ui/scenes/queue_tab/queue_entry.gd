class_name QueueEntry
extends Control

@export var image: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var action_btn: Button

var item_data: QueueItem

func _ready() -> void:
	action_btn.gui_input.connect(_on_gui_input)
	action_btn.pressed.connect(_on_pressed)
	action_btn.toggled.connect(_handle_theme_labels)

func set_data(queue_item: QueueItem, btn_group: ButtonGroup = null) -> void:
	var song: Song = queue_item.song
	if song == null:
		return

	image.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	item_data = queue_item

	action_btn.button_group = btn_group

func _get_request_obj_wrap() -> RequestObj:
	return RequestObj.new(
			item_data.song,
			item_data.song_context_type,
			item_data.song_source_id,
			item_data.id
		)

func _on_pressed() -> void:
	AppEvents.audio.play_song.emit(
		_get_request_obj_wrap()
	)

# The theme's don't handle selected btns well since their text is actually 2 seperate labels
# and not the buttons text hence this function to handle them specially
func _handle_theme_labels(selected: bool) -> void:
	if selected:
		for label: Label in [
			artist_label,
			title_label
		]:
			label.add_theme_color_override("font_color", Color())
	else:
		for label: Label in [
			artist_label,
			title_label
		]:
			label.remove_theme_color_override("font_color")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				AppEvents.ui.show_context_menu.emit(_get_request_obj_wrap())
			_:
				return
