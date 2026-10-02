class_name QueueEntry
extends Control

@export var image: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var action_btn: Button

var song_data: Song


func set_data(song: Song, btn_group: ButtonGroup = null) -> void:
	if song == null:
		return

	image.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	song_data = song

	action_btn.button_group = btn_group
	action_btn.pressed.connect(_on_pressed)
	action_btn.toggled.connect(_handle_theme_labels)


func _on_pressed() -> void:
	AppEvents.audio.play_song.emit(
		RequestObj.new(
			song_data,
			AppState.audio_handler.current_song_section,
			AppState.audio_handler.current_song_source_id,
		)
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
