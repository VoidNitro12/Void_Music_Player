class_name EntryInfoPopup
extends Window
## Popup for displaying read only information of an [EntryData]

## Fields contained in the popup
enum FieldSections {
	TITLE,
	ARTIST,
	ALBUM,
	DURATION,
	YEAR,
	DATE_ADDED,
	FILE_PATH,
}

@export var root_control: Panel
@export var containers: Dictionary[FieldSections, HBoxContainer]
@export var image_rect: TextureRect
@export var data_title: LineEdit
@export var artist: LineEdit
@export var album: LineEdit
@export var duration: LineEdit
@export var year: LineEdit
@export var date_added: LineEdit
@export var file_path: LineEdit

## Current data the entry holds
var data_resource: EntryData


func _ready() -> void:
	close_requested.connect(_send_close_request)


## Sets up the container with relevant data
func set_data(data: EntryData) -> void:
	if data == null:
		return

	var unused_fields: Array[FieldSections]

	self.title = data.title + " Info"
	image_rect.texture = data.cover
	data_title.text = data.title

	if data is Song:
		artist.text = data.artist
		album.text = data.album
		duration.text = AppTool.int_to_timestamp(data.raw_length)
		year.text = str(data.release_year)
		file_path.text = data.path
		file_path.tooltip_text = data.path
	elif data is Playlist:
		unused_fields = [
			FieldSections.ARTIST,
			FieldSections.ALBUM,
			FieldSections.YEAR,
			FieldSections.FILE_PATH,
		]
	elif data is Album:
		artist.text = data.artist
		year.text = str(data.release_year)
		unused_fields = [FieldSections.ALBUM, FieldSections.FILE_PATH]

	for field: FieldSections in unused_fields:
		containers[field].visible = false

	data_resource = data


func _send_close_request() -> void:
	AppEvents.ui.close_entry_info_popup.emit(data_resource)
