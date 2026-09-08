class_name EntryInfoPopup
extends Window

@export var root_control: Panel
@export var image_rect: TextureRect
@export var song_title: LineEdit
@export var artist: LineEdit
@export var album: LineEdit
@export var duration: LineEdit
@export var year: LineEdit
@export var date_added: LineEdit
@export var file_path: LineEdit

var data_resource: RequestObj

func _ready() -> void:
	close_requested.connect(_send_close_request)

func set_data(data: RequestObj) -> void:
	if data == null:
		return
	if not data.entry_data is Song:
		return
	var song: Song = data.entry_data
	
	image_rect.texture = song.cover
	song_title.text = song.title
	artist.text = song.artist
	album.text = song.album
	duration.text = AppTool.float_to_timestamp(song.raw_length)
	year.text = str(song.release_year)
	file_path.text = song.path
	
	data_resource = data

func _send_close_request() -> void: 
	AppEvents.close_entry_info_popup.emit(data_resource.entry_data)
