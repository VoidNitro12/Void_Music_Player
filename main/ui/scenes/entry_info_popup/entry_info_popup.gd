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
var data_resource: RequestObj


func _ready() -> void:
	close_requested.connect(_send_close_request)


## Sets up the container with relevant data
func set_data(data: RequestObj) -> void:
	if data == null:
		return

	var unused_fields: Array[FieldSections]
	var detail: EntryData = data.entry_data

	self.title = detail.title + " Info"
	image_rect.texture = detail.cover
	data_title.text = detail.title

	if data.entry_data is Song:
		artist.text = detail.artist
		album.text = detail.album
		duration.text = AppTool.float_to_timestamp(detail.raw_length)
		year.text = str(detail.release_year)
		file_path.text = detail.path
		file_path.tooltip_text = detail.path
	elif data.entry_data is Playlist:
		unused_fields = [
			FieldSections.ARTIST,
			FieldSections.ALBUM,
			FieldSections.YEAR,
			FieldSections.FILE_PATH,
		]
	elif data.entry_data is Album:
		artist.text = detail.artist
		year.text = str(detail.release_year)
		unused_fields = [FieldSections.ALBUM, FieldSections.FILE_PATH]

	for field: FieldSections in unused_fields:
		containers[field].visible = false

	data_resource = data


func _send_close_request() -> void:
	AppEvents.close_entry_info_popup.emit(data_resource.entry_data)
