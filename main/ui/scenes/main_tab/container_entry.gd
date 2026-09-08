class_name ContainerEntry
extends Control
## A visual packet for displaying songs, playlists and albums

enum ViewType{LIST,GRID}
enum EntryType{SONG,PLAYLIST}

@export_group("List Form", "list_")
@export var list_base: Panel
@export var list_image_rect: TextureRect
@export var list_title_label: Label
@export var list_artist_label: Label
@export var list_album_label: Label
@export var list_duration_label: Label
@export var list_btn: Button

@export_group("Grid Form", "grid_")
@export var grid_base: Panel
@export var grid_image_rect: TextureRect
@export var grid_title_label: Label
@export var grid_artist_label: Label
@export var grid_btn: Button

var data_obj: RequestObj
var entry_type: EntryType
var entry_source: AppTool.MainTabSections

func _ready() -> void:
	for btn: Button in [grid_btn,list_btn]:
		btn.gui_input.connect(act_on_press)

func set_data(data: RequestObj) -> void: 
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
		list_album_label.text = detail.album
		list_duration_label.text = AppTool.float_to_timestamp(detail.raw_length)
		grid_artist_label.text = detail.artist
	elif detail is Playlist:
		pass
	elif detail is Album:
		list_artist_label.text = detail.artist
		grid_artist_label.text = detail.artist

func change_view_type(view_type: ViewType)-> void: 
	var on: bool
	match view_type:
		ViewType.LIST:
			on = false
			custom_minimum_size = list_base.custom_minimum_size
		ViewType.GRID:
			on = true
			custom_minimum_size = grid_base.custom_minimum_size
		_: 
			push_error("Invalid Option")
			return
	
	list_base.visible = !on
	grid_base.visible = on

func act_on_press(event: InputEvent)-> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if data_obj.entry_data is Song:
					AppEvents.play_song.emit(data_obj)
				elif data_obj.entry_data is Playlist:
					pass
			MOUSE_BUTTON_RIGHT:
				AppEvents.show_context_menu.emit(data_obj)
			_:
				pass
