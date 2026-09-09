class_name Song
extends EntryData
## Resource for a discovered audio file used by the app

## Artist of the song
@export var artist: String

## Album this song belongs too
@export var album: String

## Year this song was released
@export var release_year: int

## Duration of this song
@export var raw_length: float

## Location of the song on the user's directory
@export var path: String


## Returns a stream of the actual audio resource
func get_song_stream() -> AudioStream:
	if not FileAccess.file_exists(self.path):
		push_error("Song not found")
		return
	var extension: String = path.get_extension().to_lower()
	var file_data: PackedByteArray = FileAccess.get_file_as_bytes(self.path)
	var stream: AudioStream = AppTool.get_audio_stream(extension)
	if stream == null:
		return

	stream.data = file_data
	return stream
