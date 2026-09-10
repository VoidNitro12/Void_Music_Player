class_name FileScanner
extends RefCounted
## Handles scanning, caching and indexing of Audio files

## All formats that are supported by this App
const VALID_EXTENSIONS: PackedStringArray = ["mp3", "wav", "ogg"]


## Scans and returns an array of [Song] resources found in [param dir_path]
## [b]TODO:[/b] Add option for scanning subfolders
static func get_audio_files(dir_path: String) -> Array[Song]:
	if not DirAccess.dir_exists_absolute(dir_path):
		push_error("\"%s\" is not a valid path" % dir_path)
		return []
	

	var paths: PackedStringArray = _scan_folder_for_audio(dir_path)

	var cache: Dictionary = load_meta_data_cache() # {"song_path": {song data}}
	
	var songs: Array[Song]

	# Extract metadata
	for path: String in paths:
		var last_modified: int = FileAccess.get_modified_time(path)
		var file_size: int = FileAccess.get_size(path)

		var cached: Dictionary = cache.get(path, { })

		var cache_is_valid: bool = (
			not cached.is_empty() and (last_modified == cached.get("last_modified", 0))
			and file_size == cached.get("file_size", -1)
		)

		if cache_is_valid:
			var song: Song = Song.new()
			song.id = AppState.get_id_from_path(path)
			song.title = cached.get("title", "")
			song.artist = cached.get("artist", "")
			song.album = cached.get("album", "")
			song.release_year = cached.get("release_year", 0)
			song.raw_length = cached.get("raw_length", 0.0)
			song.cover_path = cached.get("cover_path", "")
			songs.append(song)
		else:
			var song: Song = create_song_from_path(path)
			if song == null: 
				continue
			
			songs.append(song)
			
			cache[song.path] = {
				"title": song.title,
				"artist": song.artist,
				"album": song.album,
				"release_year": song.release_year,
				"raw_length": song.raw_length,
				"cover_path": song.cover_path,
				"last_modified": last_modified,
				"file_size": file_size,
			}
	_save_meta_data_cache(cache)
	return songs

## Creates a brand new [Song] Resource from the given [param path].[br]
## Assigns an id if the song does not already exist else returns the existing resource
static func create_song_from_path(path: String) -> Song: 
	
	var id: int = AppState.get_id_from_path(path)
	if AppState.all_tracks.has(id):
		return AppState.all_tracks[id]
	
	var extension: String = path.get_extension().to_lower()
	var file_data: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if file_data.is_empty():
		push_warning("Could not read file \"%s\"" % path)
		return null

	var stream: AudioStream = AppTool.get_audio_stream(extension)
	if stream == null:
		return null

	stream.data = file_data

	var meta_data: MusicMetadata = MusicMetadata.new(stream)
	
	var song: Song = Song.new()
	song.title = meta_data.title.remove_chars("\n\t")
	song.artist = meta_data.artist.remove_chars("\n\t")
	song.album = meta_data.album.remove_chars("\n\t")
	song.release_year = meta_data.year
	song.path = path
	if meta_data.has_tag("duration"):
		song.raw_length = meta_data.tags["duration"]

	var cover_path: String = AppState.SONG_COVER_CACHE.path_join(
		"%s.png" % str(abs(path.hash()))
	)
	var cover: Image = meta_data.cover.get_image()
	cover.save_png(cover_path)
	song.cover_path = cover_path
	
	song.id = id
	AppState.all_tracks[id] = song
	
	return song

## Scans and returns an array of [Album] resources created from the provided array of songs
static func get_albums(songs: Array[Song]) -> Array[Album]:
	var albums: Array[Album]
	var look_up: Dictionary[String, Album]

	for song: Song in songs:
		if song.album.is_empty():
			continue

		if look_up.has(song.album):
			look_up[song.album].songs[song.id] = song
			continue

		var album: Album = Album.new()
		album.title = song.album
		album.songs[song.id] = song
		album.release_year = song.release_year #assuming all songs are from the same year
		# as the meta data plugin does not have a field for album year
		album.cover_path = song.cover_path # same as above
		look_up[song.album] = album

	for a: Album in look_up.values():
		albums.append(a)

	return albums

## Loads and returns a Dictionary representing the current meta data cache 
static func load_meta_data_cache() -> Dictionary:
	if not FileAccess.file_exists(AppState.META_DATA_CACHE):
		return { }

	var file: FileAccess = FileAccess.open(AppState.META_DATA_CACHE, FileAccess.READ)
	if file == null:
		push_error("Could not open meta data cache")
		return { }

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	return parsed


static func _scan_folder_for_audio(dir: String) -> PackedStringArray:
	var music_dir: DirAccess = DirAccess.open(dir)
	if not music_dir:
		push_error("Could not open path at \"%s\"" % dir)
		return []

	var audio: PackedStringArray = []

	music_dir.list_dir_begin()
	var file_name: String = music_dir.get_next()
	while file_name != "":
		if not music_dir.current_is_dir():
			if not VALID_EXTENSIONS.has(file_name.get_extension().to_lower()):
				file_name = music_dir.get_next()
				continue

			var path: String = dir.path_join(file_name)
			audio.append(path)

		file_name = music_dir.get_next()

	return audio


static func _save_meta_data_cache(cache: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(AppState.META_DATA_CACHE, FileAccess.WRITE)
	if file == null:
		push_error("Could not save meta data cache")
		return

	var result: bool = file.store_string(JSON.stringify(cache, "\t"))
	if not result:
		push_error("Error while saving meta data cache")
		return
