extends Node
class_name MusicHandler

var parent 

var a = []
var repeat: bool = false
var all_songs: Array
var all_playlists: Array
var total_songs_num: int = 0
var total_playlist_num: int = 0
var audio_stream = AudioStreamPlayer.new()
var music_is_playing: bool = false
var dragging_seeker: bool = false
var seeker_value: float
var seeker_max: float
var song_paused_at: float
var current_queue: Array
var base_queue: Array
var current_song: Song
var current_playlist: Playlist
var current_source: Object

signal proccesed_songs
signal current_details
signal change_song

func _ready() -> void:
	parent = get_parent()
	parent.add_child(audio_stream)

func _process(_delta: float) -> void:
	check_audio_play()
	if music_is_playing:
		var playback = audio_stream.get_playback_position()
		var minutes = floor(playback/60.0)
		var seconds = int(playback) % 60
		var current_play_time = "%02d:%02d" % [minutes,seconds]
		if int(seeker_value) == int(seeker_max):
			if repeat:
				audio_stream.play()
			else:
				next_song()
		current_details.emit(current_play_time,playback)

func _process_all_music(dir: DirAccess, dir_path: String):
	# Get audio files
	var songs: Array[Song] = []
	var total_songs = 0
	var music_dir = dir
	
	if music_dir:
		music_dir.list_dir_begin()
		var file_name = music_dir.get_next()
		while file_name != "":
			if not music_dir.current_is_dir() and file_name.ends_with(".mp3"):
				var full_path = dir_path.path_join(file_name)
				var split_name = file_name.split(".mp3")
				var song = Song.new()
				song.id = total_songs
				song.title = split_name[0]
				song.path = full_path
				total_songs += 1
				songs.append(song)
				file_name = music_dir.get_next()
	else:
		push_error("Failed to open Directory")
		return
		
	# Extract metadata 
	var song_id = 0
	while song_id < total_songs:
		var song_object: Song = songs[song_id]
		var song_path = song_object.path
		var meta_read = FileAccess.get_file_as_bytes(song_path)
		var sound = AudioStreamMP3.new()
		sound.data = meta_read
		
		a.append(MusicMetadata.new(sound))
		
		var tagReader := MP3ID3Tag.new()
		tagReader.stream = sound
		song_object.artist = tagReader.getArtist()
		song_object.album = tagReader.getAlbum()
		#song_object.release_year = tagReader.getYear()
		
		song_object.raw_length = sound.get_length()
		var raw_length = sound.get_length()
		var minutes = floor(raw_length/60.0)
		var seconds = int(raw_length) % 60
		var song_length = "%02d:%02d" % [minutes,seconds]
		song_object.duration = song_length
		
		song_id += 1
		
	all_songs = songs
	total_songs_num = total_songs
	thread_done.call_deferred()

func thread_done():
	proccesed_songs.emit()

func check_audio_play():
	music_is_playing = audio_stream.playing 

func scan(dir: String) -> String:
	var music_dir = DirAccess.open(dir)
	if not music_dir:
		return "Invalid Directory"
	
	var _scan_task_id = WorkerThreadPool.add_task(_process_all_music.bind(music_dir,dir), true)
	return "OK"

func play_song(song: Song, source: Object):
	set_queue(source)
	audio_stream.stop()
	audio_stream.stream = null
	var stream = song.get_song_stream()
	if not stream:
		return
	audio_stream.stream = stream
	seeker_max = song.raw_length
	audio_stream.play()
	current_song = song

func seek(value: float):
	audio_stream.play(value)
	seeker_value = value

func add_playlist(playlist_name: String) -> Playlist:
	var id = total_playlist_num
	var date = Time.get_date_dict_from_system()
	var date_created = "%s/%s/%s"%[date.day,date.month,date.year]
	var playlist = Playlist.new(id,playlist_name,date_created)
	all_playlists.append(playlist)
	total_playlist_num += 1
	return playlist

func rename_playlist(playlist_name: String) -> void:
	current_playlist.title = playlist_name

func delete_playlist() -> void:
	all_playlists.erase(current_playlist)
	total_playlist_num -= 1

func set_queue(source: Object):
	if source is Playlist:
		base_queue = source.songs
	elif source == null:
		base_queue = all_songs
	current_source = source
	current_queue = base_queue

func pause_play():
	if audio_stream.playing:
		song_paused_at = audio_stream.get_playback_position()
		audio_stream.stop()
	else:
		audio_stream.play(song_paused_at)

func next_song(to_crossfade: bool = false) -> Song:
	var idx = current_queue.find(current_song)
	var total_idx = current_queue.size()
	var to_play
	
	if idx < total_idx:
		idx += 1
		to_play = current_queue[idx]
	else:
		to_play = current_queue[0]
	
	if not to_crossfade:
		change_song.emit(to_play)
		return null
	return to_play

func prev_song():
	var idx = current_queue.find(current_song)
	var to_play
	
	if idx >= 0:
		idx -= 1
		to_play = current_queue[idx]
	else:
		to_play = current_queue[-1]
	change_song.emit(to_play)

func shuffle(Bool: bool):
	if Bool:
		current_queue.shuffle()
	else:
		current_queue = base_queue

func edit_songs_playlist(songs: Array[Song]) -> bool:
	if not current_playlist:
		push_error("No current Playlist available")
		return false
	
	current_playlist.songs.clear()
	current_playlist.songs.append_array(songs)
	return true
