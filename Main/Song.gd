class_name Song
extends  Resource

@export var id: int
@export var title: String
@export var path: String
@export var raw_length: float
@export var duration: String 
@export var artist: String
@export var release_year: String
@export var album: String
var cover: Texture2D

func get_song_stream() -> AudioStreamMP3:
	if not FileAccess.file_exists(self.path):
		push_error("Song not found")
		return
	
	var meta_read = FileAccess.get_file_as_bytes(self.path)
	var sound = AudioStreamMP3.new()
	sound.data = meta_read
	return sound
 
func get_song_cover() -> Texture2D:
	if self.cover:
		return self.cover
	
	var sound = get_song_stream()
	var tagReader := MP3ID3Tag.new()
	tagReader.stream = sound
	var cover_img: Image = tagReader.getAttachedPicture()
	self.cover = ImageTexture.create_from_image(cover_img)
	return self.cover
