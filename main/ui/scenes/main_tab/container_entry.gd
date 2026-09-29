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

@export_group("List Form", "list_")
@export var list_base: Panel
@export var selection_checkbox: CheckBox
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

var current_active_btn: Button

var in_main_tab: bool = false


## Sets up the container with relevant data.[br] [param is_selection] determines whether the
## checkbox is visible and in turn makes this solely for selection.[br] [param display only]
## determines if any of the containers buttons are functional, overrides [param is_selection]
func set_data(
	data: RequestObj,
	is_selection: bool = false,
	display_only: bool = false,
	btn_group: ButtonGroup = null,
	in_main: bool = false, #MainTab List view needs a larger cutosm minimum size than other areas
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
			if not btn.gui_input.is_connected(_act_on_press):
				btn.gui_input.connect(_act_on_press)
			if btn_group != null:
				btn.button_group = btn_group
		else:
			btn.disabled = true

	if not display_only:
		selection_checkbox.visible = is_selection

	in_main_tab = in_main


## Changes the current view method of the entry
func change_view_type(view_type: ViewType) -> void:
	var on: bool
	match view_type:
		ViewType.LIST:
			on = false
			current_active_btn = list_btn
			# Lists height should be constant
			custom_maximum_size = Vector2(-1, list_base.custom_maximum_size.y)
			if in_main_tab:
				custom_minimum_size = Vector2(
					(list_base.custom_minimum_size.x * 2.5),
					list_base.custom_minimum_size.y,
				)
		ViewType.GRID:
			on = true
			current_active_btn = grid_btn
			# Grids size should be constant
			custom_minimum_size = grid_base.custom_minimum_size
			custom_maximum_size = grid_base.custom_minimum_size
		_:
			AppEvents.log_error.emit(
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
			AppEvents.log_error.emit(ErrorLogger.LogLevel.ERROR, "Invalid Option for search_type")
			return false


# override for mouse clicks on the entries buttons
func _act_on_press(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not selection_checkbox.visible:
					if data_obj.entry_data is Song:
						AppEvents.audio.play_song.emit(data_obj)
					elif data_obj.entry_data is Playlist:
						AppEvents.ui.open_packed_entry.emit(data_obj.entry_data)
					elif data_obj.entry_data is Album:
						AppEvents.ui.open_packed_entry.emit(data_obj.entry_data)
				else:
					selection_checkbox.button_pressed = !selection_checkbox.button_pressed
			MOUSE_BUTTON_RIGHT:
				AppEvents.ui.show_context_menu.emit(data_obj)
			_:
				pass
