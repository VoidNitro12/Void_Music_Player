class_name SaveSystem
extends RefCounted
## Static class for handling persistence for app related data


## Save all relevant user data
## TODO: Store loaded dir paths after updating settings to have an option to
static func save_data() -> void:
	var file: FileAccess = FileAccess.open(AppState.SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save app data")
		return

	#load the current save if exists
	var save_dict: Dictionary = _get_save_data()

	# For tracks save only playlists, songs and albums are covered by the meta data cache
	# "playlists": {id: {data, "songs":[Array of song_paths]}}
	for playlist: Playlist in AppState.playlists.values():
		#Check the current save if it has this playlist to avoid unnecessary rewrites
		if save_dict.has("playlists") and save_dict.playlists.has(playlist.id):
			return

		if not save_dict.has("playlists"):
			save_dict["playlists"] = { }

		save_dict.playlists[playlist.id] = {
			"title": playlist.title,
			"description": playlist.description,
			"date_dict": playlist.date_dict,
			"cover_path": playlist.cover_path,
		}

		var store_songs: PackedStringArray
		for song: Song in playlist.songs.values():
			store_songs.append(song.path)

		save_dict.playlists[playlist.id]["songs"] = store_songs

	var result: bool = file.store_string(JSON.stringify(save_dict, "\t"))
	if not result:
		push_error("Error while saving app data")
		return
	file.close()


## load and set all relevant user data
static func load_data() -> void:
	var parsed: Dictionary = _get_save_data()

	if parsed.has("playlists"):
		for key: String in parsed.playlists.keys():
			var id: int = key.to_int()
			var found_obj: Dictionary = parsed.playlists[key]
			var playlist: Playlist = Playlist.new()
			playlist.id = id
			playlist.title = found_obj.get("title", "")
			playlist.description = found_obj.get("description", "")
			playlist.date_dict.assign(
				found_obj.get("date_dict", { "day": 0, "month": 0, "year": 0, "weekday": 0 })
			)
			playlist.cover_path = found_obj.get("cover_path", "")
			var loaded_songs: PackedStringArray = found_obj.get("songs", [])
			for path: String in loaded_songs:
				var song: Song = FileScanner.create_song_from_path(path)
				if song == null:
					continue
				var song_id: int = AppState.get_id_from_path(path)
				song.id = song_id
				if not AppState.all_tracks.has(song_id):
					AppState.all_tracks[song_id] = song
				playlist.songs[song.id] = song

			AppState.playlists[id] = playlist


## Stores the updated _id_tracker to disk
static func save_id_tracker(id_tracker: Dictionary[String, int]) -> void:
	var file: FileAccess = FileAccess.open(AppState.ID_TRACKER_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open id tracker save")
		return

	var result: bool = file.store_string(JSON.stringify(id_tracker, "\t"))
	if not result:
		push_error("Error while saving app data")
		return
	file.close()


## Loads the _id_tracker from disk
static func load_id_tracker() -> Dictionary[String, int]:
	var tracker: Dictionary[String, int]
	if not FileAccess.file_exists(AppState.ID_TRACKER_SAVE_PATH):
		return tracker

	var file: FileAccess = FileAccess.open(AppState.ID_TRACKER_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open id tracker save")
		return tracker

	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	tracker.assign(parsed)
	file.close()
	return tracker


static func _get_save_data() -> Dictionary:
	if not FileAccess.file_exists(AppState.SAVE_FILE_PATH):
		return { }

	var file: FileAccess = FileAccess.open(AppState.SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open app data save")
		return { }

	var parsed: Dictionary
	var check: Variant = JSON.parse_string(file.get_as_text())
	if typeof(check) == TYPE_NIL:
		return { }
	if typeof(check) == TYPE_DICTIONARY:
		parsed = check
	else:
		return { }

	file.close()
	return parsed
