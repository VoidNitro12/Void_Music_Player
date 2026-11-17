class_name ContainerEntry
extends SceneBase
## A visual packet for displaying songs, playlists and albums

enum SortType {
	ALPHA_TITLE, ## Sort by its [EntryData] resource title alphabetically
	ALPHA_ARTIST, ## Sort by its [EntryData] resource artist alphabetically
	SEARCH_TITLE, ## Sort by its [EntryData] resource title via a given string
	SEARCH_ARTIST, ## Sort by its [EntryData] resource artist via a given string
}

@export_group("Scene Nodes", "_")
@export var _base: Panel
@export var _image_rect: TextureRect
@export var _title_label: Label
@export var _artist_label: Label
@export var _duration_label: Label
@export var _btn: Button
@export var _selection_checkbox: CheckBox

## Current data the entry holds
var data_obj: RequestObj

## Container in [MainTab] the [member data_obj] originated from
var entry_source: AppTool.MainTabSections

# grid has no duration label
var _has_duration_label: bool = false

func _ready() -> void:
	_btn.gui_input.connect(_on_gui_input)
	_btn.pressed.connect(_on_pressed)
	_btn.toggled.connect(_handle_theme_labels)


## Sets up the container with relevant data.[br] [param is_selection] determines whether the
## checkbox is visible and in turn makes this solely for selection.[br] [param display only]
## determines if any of the containers buttons are functional, overrides [param is_selection]
func set_data(
	data: RequestObj,
	is_selection: bool = false,
	display_only: bool = false,
	btn_group: ButtonGroup = null,
) -> void:
	if data == null:
		return
	
	# if data_obj != null and data.entry_data == data_obj.entry_data:
	# 	return

	data_obj = data
	var detail: EntryData = data.entry_data

	_image_rect.texture = detail.cover
	_title_label.text = detail.title

	if detail is Song:
		_artist_label.text = detail.artist
		if _has_duration_label:
			_duration_label.text = AppTool.duration_to_timestamp(detail.raw_length)
	elif detail is Playlist:
		pass
	elif detail is Album:
		_artist_label.text = detail.artist

	if display_only:
		_btn.disabled = true

	_btn.button_group = btn_group

	if not display_only:
		_selection_checkbox.visible = is_selection


## Searches the entries [EntryData] and returns a bool on if it fits the search or not.[br]
## If the entry houses a [Playlist] any attempt to search by [SortType.SEARCH_ARTIST] will return
## true regardless
func in_search(type: SortType, text: String = "") -> bool:
	text = text.strip_edges()
	if text.is_empty():
		# reset to visible if the sent string is just non readable characters
		return true

	match type:
		SortType.SEARCH_TITLE:
			return (text.to_lower() in data_obj.entry_data.title.to_lower())
		SortType.SEARCH_ARTIST:
			if data_obj.entry_data is Playlist:
				return true
			return (text.to_lower() in data_obj.entry_data.artist.to_lower())
		_:
			_bus.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for search_type",
			)
			return false


## Sets the highlight for the list and grid buttons
func set_btn_selection(selected: bool) -> void:
	_btn.button_pressed = selected


func _on_pressed() -> void:
	if _selection_checkbox.visible:
		return
	var data: EntryData = data_obj.entry_data
	if data is Song:
		_bus.audio.play_song.emit(data_obj)
	elif data is Playlist or data is Album:
		_bus.ui.open_packed_entry.emit(data_obj.entry_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if _selection_checkbox.visible:
					_selection_checkbox.button_pressed = !_selection_checkbox.button_pressed
			MOUSE_BUTTON_RIGHT:
				_bus.ui.show_context_menu.emit(data_obj)
			_:
				return


# The theme's don't handle selected btns well since their text is actually 2 separate labels
# and not the buttons text hence this function to handle them specially
func _handle_theme_labels(selected: bool) -> void:
	var labels: Array[Label] = [_artist_label, _title_label]
	if _has_duration_label:
		labels.append(_duration_label)
	if selected:
		for label: Label in labels:
			label.add_theme_color_override(
				"font_color",
				_btn.get_theme_color("font_pressed_color", "Button"),
			)
	else:
		for label: Label in labels:
			label.remove_theme_color_override("font_color")
