class_name Song
extends  Resource

@export var id: int
@export var title: String
@export var path: String
@export var artist: String
@export var album: String
@export var cover: ImageTexture
@export var raw_length: float
@export var release_year: int




func get_song_stream() -> AudioStreamMP3:
	if not FileAccess.file_exists(self.path):
		push_error("Song not found")
		return
	
	var meta_read = FileAccess.get_file_as_bytes(self.path)
	var sound = AudioStreamMP3.new()
	sound.data = meta_read
	return sound
 
