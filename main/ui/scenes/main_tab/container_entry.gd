class_name ContainerEntry
extends Control
## A visual packet for displaying songs, playlists and albums

## Options for how the data contained in this entry should be displayed
enum ViewType {
	LIST,
	GRID,
}

enum SortType {
	ALPHA_TITLE, ## Sort by its [EntryData] resource title alphabetically
	ALPHA_ARTIST, ## Sort by its [EntryData] resource artist alphabetically
	SEARCH_TITLE, ## Sort by its [EntryData] resource title via a given string
	SEARCH_ARTIST, ## Sort by its [EntryData] resource artist via a given string
}

@export var selection_checkbox: CheckBox

@export_group("List Form", "list_")
@export var list_base: Panel
@export var list_image_rect: TextureRect
@export var list_title_label: Label
@export var list_artist_label: Label
@export var list_duration_label: Label
@export var list_btn: Button

@export_group("Grid Form", "grid_")
@export var grid_base: Panel
@export var grid_image_rect: TextureRect
@export var grid_title_label: Label
@export var grid_artist_label: Label
@export var grid_btn: Button

## Current data the entry holds
var data_obj: RequestObj

## Container in [MainTab] the [member data_obj] originated from
var entry_source: AppTool.MainTabSections

var in_main_tab: bool = false


## Sets up the container with relevant data.[br] [param is_selection] determines whether the
## checkbox is visible and in turn makes this solely for selection.[br] [param display only]
## determines if any of the containers buttons are functional, overrides [param is_selection]
func set_data(
	data: RequestObj,
	is_selection: bool = false,
	display_only: bool = false,
	list_btn_group: ButtonGroup = null,
	grid_btn_group: ButtonGroup = null,
	in_main: bool = false, #MainTab List view needs a larger custom minimum size than other areas
) -> void:
	if data == null:
		return

	data_obj = data
	var detail: EntryData = data.entry_data

	list_image_rect.texture = detail.cover
	list_title_label.text = detail.title

	grid_image_rect.texture = detail.cover
	grid_title_label.text = detail.title

	if detail is Song:
		list_artist_label.text = detail.artist
		list_duration_label.text = AppTool.int_to_timestamp(detail.raw_length)
		grid_artist_label.text = detail.artist
	elif detail is Playlist:
		pass
	elif detail is Album:
		list_artist_label.text = detail.artist
		grid_artist_label.text = detail.artist

	for btn: Button in [grid_btn, list_btn]:
		if not display_only:
			if not btn.gui_input.is_connected(_on_gui_input):
				btn.gui_input.connect(_on_gui_input)
			if not btn.pressed.is_connected(_on_pressed):
				btn.pressed.connect(_on_pressed)
			btn.toggled.connect(_handle_theme_labels)
		else:
			btn.disabled = true
	grid_btn.button_group = grid_btn_group
	list_btn.button_group = list_btn_group

	if not display_only:
		selection_checkbox.visible = is_selection

	in_main_tab = in_main


## Changes the current view method of the entry
func change_view_type(view_type: ViewType) -> void:
	var on: bool
	match view_type:
		ViewType.LIST:
			on = false
			# Lists height should be constant
			custom_maximum_size = Vector2(-1, list_base.custom_maximum_size.y)
			if in_main_tab:
				custom_minimum_size = Vector2(
					(list_base.custom_minimum_size.x * 2.5),
					list_base.custom_minimum_size.y,
				)
		ViewType.GRID:
			on = true
			# Grids size should be constant
			custom_minimum_size = grid_base.custom_minimum_size
			custom_maximum_size = grid_base.custom_minimum_size
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for view_type in ContainerEntry.change_view_type()",
			)
			return

	list_base.visible = !on
	grid_base.visible = on


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
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for search_type",
			)
			return false


## Sets the highlight for the list and grid buttons
func set_btn_selection(selected: bool) -> void:
	grid_btn.button_pressed = selected
	list_btn.button_pressed = selected


func _on_pressed() -> void:
	if selection_checkbox.visible:
		return
	var data: EntryData = data_obj.entry_data
	if data is Song:
		AppEvents.audio.play_song.emit(data_obj)
	elif data is Playlist or data is Album:
		AppEvents.ui.open_packed_entry.emit(data_obj.entry_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if selection_checkbox.visible:
					selection_checkbox.button_pressed = !selection_checkbox.button_pressed
			MOUSE_BUTTON_RIGHT:
				AppEvents.ui.show_context_menu.emit(data_obj)
			_:
				return


# The theme's don't handle selected btns well since their text is actually 2 seperate labels
# and not the buttons text hence this function to handle them specially
func _handle_theme_labels(selected: bool) -> void:
	if selected:
		for label: Label in [
			list_artist_label,
			list_title_label,
			grid_artist_label,
			grid_title_label,
			list_duration_label,
		]:
			label.add_theme_color_override("font_color", Color())
	else:
		for label: Label in [
			list_artist_label,
			list_title_label,
			grid_artist_label,
			grid_title_label,
			list_duration_label,
		]:
			label.remove_theme_color_override("font_color")
