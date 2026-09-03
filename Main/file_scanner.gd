class_name FileScanner
extends RefCounted

const VALID_EXTENSIONS: PackedStringArray = ["mp3","wav","ogg"]

static func scan_for_audio(dir_path: String) -> Array[Song]: 
	var music_dir: DirAccess = DirAccess.open(dir_path)
	if not music_dir:
		return Array[Song]
	
	var songs: Array[Song] = []
	var total_songs: int = 0
	
	music_dir.list_dir_begin()
	var file_name = music_dir.get_next()
	while file_name != "":
		if not music_dir.current_is_dir():
			if not file_name.get_extension() in VALID_EXTENSIONS:
				file_name = music_dir.get_next()
				continue
			
			var full_path = dir_path.path_join(file_name)
			var song = Song.new()
			song.id = total_songs
			song.path = full_path
			total_songs += 1
			songs.append(song)
			file_name = music_dir.get_next()
	
	# Extract metadata 
	var song_id = 0
	while song_id < total_songs:
		var song_object: Song = songs[song_id]
		var song_path = song_object.path
		var meta_read = FileAccess.get_file_as_bytes(song_path)
		var stream = AudioStreamMP3.new()
		stream.data = meta_read
		
		var meta_data: MusicMetadata = MusicMetadata.new(stream)
		
		song_object.title = meta_data.title
		song_object.album = meta_data.album
		song_object.cover = meta_data.cover
		song_object.release_year = meta_data.year
		song_object.raw_length = meta_data.tags["duration"]
		song_id += 1
	
	return songs
