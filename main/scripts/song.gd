class_name Song
extends EntryData

@export var artist: String
@export var album: String
@export var release_year: int
@export var raw_length: float
@export var path: String



func get_song_stream() -> AudioStream:
	if not FileAccess.file_exists(self.path):
		push_error("Song not found")
		return
	var extension: String = path.get_extension().to_lower()
	var file_data: PackedByteArray = FileAccess.get_file_as_bytes(self.path)
	var stream: AudioStream
	match extension:
		"mp3":
			stream = AudioStreamMP3.new()
		"wav":
			stream = AudioStreamWAV.new()
		"ogg":
			stream = AudioStreamOggVorbis.new()
		_:
			push_error("Unsupported audio extension \"%s\"" % extension)

	stream.data = file_data
	return stream
