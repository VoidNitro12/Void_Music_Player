class_name FileScanner
extends RefCounted

const VALID_EXTENSIONS: PackedStringArray = ["mp3", "wav", "ogg"]


static func get_audio_files(dir_path: String) -> Array[Song]:
	if not DirAccess.dir_exists_absolute(dir_path):
		push_error("\"%s\" is not a valid path" % dir_path)
		return []

	var songs: Array[Song] = _scan_folder_for_audio(dir_path)

	var cache: Dictionary = load_meta_data_cache() # {"song_path": {song data}}
	
	# Extract metadata
	for song: Song in songs:
		var last_modified: int = FileAccess.get_modified_time(song.path)
		var file_size: int = FileAccess.get_size(song.path)

		var cached: Dictionary = cache.get(song.path, { })

		var cache_is_valid: bool = (
			not cached.is_empty() and (last_modified == cached.get("last_modified", 0))
			and file_size == cached.get("file_size", -1)
		)

		if cache_is_valid:
			song.title = cached.get("title", "")
			song.artist = cached.get("artist", "")
			song.album = cached.get("album", "")
			song.release_year = cached.get("release_year", 0)
			song.raw_length = cached.get("raw_length", 0.0)
			song.cover_path = cached.get("cover_path", "")
		else:
			var extension: String = song.path.get_extension().to_lower()
			var file_data: PackedByteArray = FileAccess.get_file_as_bytes(song.path)
			if file_data.is_empty():
				push_warning("Could not read file \"%s\"" % song.path)
				continue

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
					continue

			stream.data = file_data
			
			var meta_data: MusicMetadata = MusicMetadata.new(stream)
			
			song.title = meta_data.title
			song.artist = meta_data.artist
			song.album = meta_data.album
			song.release_year = meta_data.year
			if meta_data.has_tag("duration"):
				song.raw_length = meta_data.tags["duration"]

			var cover: Image = meta_data.cover.get_image()
			var cover_path: String = AppState.SONG_COVER_CACHE.path_join(
				"%s.png" %str(abs(song.path.hash()))
			)
			song.cover_path = cover_path
			cover.save_png(cover_path)

			cache[song.path] = {
				"title": song.title,
				"artist": song.artist,
				"album": song.album,
				"release_year": song.release_year,
				"raw_length": song.raw_length,
				"cover_path": cover_path,
				"last_modified": last_modified,
				"file_size": file_size,
			}
	_save_meta_data_cache(cache)
	return songs

static func get_albums(songs: Array[Song]) -> Array[Album]:
	var albums: Array[Album]
	var look_up: Dictionary[String,Album]
	
	for song: Song in songs:
		if song.album.is_empty():
			continue
		
		if look_up.has(song.album):
			look_up[song.album].songs.append(song)
			continue
		
		var album: Album = Album.new()
		album.title = song.album
		album.songs.append(song)
		album.release_year = song.release_year #assuming all songs are from the same year
		# as the meta data addon does not have a field for album year
		album.cover_path = song.cover_path # same as above
		look_up[song.album] = album
	
	for a: Album in look_up.values():
		albums.append(a)
	
	return albums

static func _scan_folder_for_audio(dir: String) -> Array[Song]:
	var music_dir: DirAccess = DirAccess.open(dir)
	if not music_dir:
		push_error("Could not open path at \"%s\"" % dir)
		return []

	var songs: Array[Song] = []

	music_dir.list_dir_begin()
	var file_name: String = music_dir.get_next()
	while file_name != "":
		if not music_dir.current_is_dir():
			if not VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
				file_name = music_dir.get_next()
				continue

			var song: Song = Song.new()
			song.id = songs.size()
			song.path = dir.path_join(file_name)
			songs.append(song)

		file_name = music_dir.get_next()

	return songs


static func load_meta_data_cache() -> Dictionary:
	if not FileAccess.file_exists(AppState.META_DATA_CACHE):
		return { }

	var file: FileAccess = FileAccess.open(AppState.META_DATA_CACHE, FileAccess.READ)
	if file == null:
		push_error("Could not open meta data cache")
		return { }

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	return parsed


static func _save_meta_data_cache(cache: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(AppState.META_DATA_CACHE, FileAccess.WRITE)
	if file == null:
		push_error("Could not save meta data cache")
		return

	var result: bool = file.store_string(JSON.stringify(cache, "\t"))
	if not result:
		push_error("Error while saving meta data cache")
		return
