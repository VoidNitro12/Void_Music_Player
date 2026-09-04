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


func _ready() -> void:
	close_requested.connect(func()->void: self.queue_free())

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
