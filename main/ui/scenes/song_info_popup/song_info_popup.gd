class_name SongInfoPopup
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

var song_data: Song

func _ready() -> void:
	close_requested.connect(_send_close_request)

func set_data(song: Song) -> void: 
	if song == null: 
		return
	
	image_rect.texture = song.cover
	song_title.text = song.title
	artist.text = song.artist
	album.text = song.album
	duration.text = AppTool.float_to_timestamp(song.raw_length)
	year.text = str(song.release_year)
	file_path.text = song.path
	
	song_data = song

func _send_close_request() -> void: 
	AppEvents.close_song_info_popup.emit(song_data)
