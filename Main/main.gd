extends Control

@onready var home_page: Panel = $PageContainer/HomePage
@onready var settings_page: Panel = $PageContainer/SettingsPage
@onready var playlists_page: Panel = $PageContainer/PlaylistsPage
@onready var music_player: AudioStreamPlayer = $Music_player
@onready var setup_page: Panel = $PageContainer/SetupPage
@onready var folder_select: NativeFileDialog = $PageContainer/SetupPage/Folder_select
@onready var songs_container: VBoxContainer = $PageContainer/HomePage/SongsPanel/ScrollContainer/SongsContainer

#-----------------------------MenuBar------------------------
@onready var menu_bar: Panel = $MenuBar
@onready var home_page_button: Button = $MenuBar/VBoxContainer/HomePageButton
@onready var play_lists_button: Button = $MenuBar/VBoxContainer/PlayListsButton
@onready var settings_button: Button = $MenuBar/VBoxContainer/SettingsButton


#------------------------------CurrentlyPlaying-----------------------
@onready var prev_music_button: Button = $CurrentlyPlayingPanel/QuickControls/PrevMusicButton
@onready var play_pause_music_button: Button = $CurrentlyPlayingPanel/QuickControls/PlayPauseMusicButton
@onready var next_music_button: Button = $CurrentlyPlayingPanel/QuickControls/NextMusicButton
@onready var current_song_name_label: Label = $CurrentlyPlayingPanel/CurrentSongNameLabel
@onready var current_song_time_label: Label = $CurrentlyPlayingPanel/CurrentSongTimeLabel
@onready var seek_slider: HSlider = $CurrentlyPlayingPanel/SeekSlider
@onready var current_song_cover: TextureRect = $CurrentlyPlayingPanel/CurrentSongCover
@onready var full_song_cover: TextureRect = $CurrentlyPlayingPanel/FullCurrentSongPanel/FullSongCover
@onready var full_cover_title: Label = $CurrentlyPlayingPanel/FullCurrentSongPanel/SongMetaData/VBoxContainer/HBoxContainer/FullCoverTitle
@onready var full_cover_artist: Label = $CurrentlyPlayingPanel/FullCurrentSongPanel/SongMetaData/VBoxContainer/FullCoverArtist
@onready var full_cover_album: Label = $CurrentlyPlayingPanel/FullCurrentSongPanel/SongMetaData/VBoxContainer/FullCoverAlbum
@onready var full_cover_year: Label = $CurrentlyPlayingPanel/FullCurrentSongPanel/SongMetaData/VBoxContainer/FullCoverYear
@onready var full_current_song_panel: Panel = $CurrentlyPlayingPanel/FullCurrentSongPanel

#----------------------------------PlayLists----------------------
@onready var playlists_container: VBoxContainer = $PageContainer/PlaylistsPage/PlaylistControlPanel/Playlists/ScrollContainer/MarginContainer/PlaylistsContainer
@onready var playlist_create_button: Button = $PageContainer/PlaylistsPage/PlaylistControlPanel/PlaylistCreateButton
@onready var manage_playlist_panel: Panel = $PageContainer/PlaylistsPage/ManagePlaylistPanel
@onready var playlist_add_song_button: Button = $PageContainer/PlaylistsPage/ManagePlaylistPanel/HBoxContainer/PlaylistAddSongButton
@onready var playlist_rename_button: Button = $PageContainer/PlaylistsPage/ManagePlaylistPanel/HBoxContainer/PlaylistRenameButton
@onready var play_list_delete_button: Button = $PageContainer/PlaylistsPage/ManagePlaylistPanel/HBoxContainer/PlayListDeleteButton
@onready var playlist_name_input: LineEdit = $PageContainer/PlaylistsPage/MakePlaylist/PlaylistNameInput
@onready var confirm_playlist_name_button: Button = $PageContainer/PlaylistsPage/MakePlaylist/ConfirmPlaylistNameButton
@onready var make_playlist: Panel = $PageContainer/PlaylistsPage/MakePlaylist
@onready var playlist_songs_container: VBoxContainer = $PageContainer/PlaylistsPage/ManagePlaylistPanel/PlaylistSongsPanel/ScrollContainer/MarginContainer/PlaylistSongsContainer
@onready var availabel_songs_container: VBoxContainer = $PageContainer/PlaylistsPage/AddSongPanel/ScrollContainer/AvailabelSongsContainer
@onready var add_song_panel: Panel = $PageContainer/PlaylistsPage/AddSongPanel
@onready var addsel_songs_button: Button = $PageContainer/PlaylistsPage/AddSongPanel/AddselSongsButton
@onready var cancel_add_song_button: Button = $PageContainer/PlaylistsPage/AddSongPanel/CancelAddSongButton

var is_dragging_slider = false
var music_folder = ""
var app_data_path = "user://SaveFiles/save_data.json"
var extention_filter = ".mp3"
var current_music = {}
var music_name = ""
var current_id_song = 0
var total_id_song = 0
var current_song_length = ""
var song_paused_at = 0
var song_cover_cache = "user://Main/SongCovers/"
var menu_panels 
var current_playlist_id
var total_id_playlist = 0
var playlists = {}
var songs_to_add = []
var blocker_node 
var block_node
var current_queue = []

func _ready() -> void:
	Engine.max_fps = 30
	OS.low_processor_usage_mode = true
	PhysicsServer3D.set_active(false)
	menu_panels = [home_page,settings_page,playlists_page]
	if not DirAccess.dir_exists_absolute("user://SaveFiles/"):
			DirAccess.make_dir_recursive_absolute('user://SaveFiles/')
	if not DirAccess.dir_exists_absolute(song_cover_cache):
			DirAccess.make_dir_recursive_absolute(song_cover_cache)
	#print(ProjectSettings.globalize_path("user://"))
	startup()

func _process(_delta: float) -> void:
	if music_player.playing:
		var raw_length = music_player.get_playback_position()
		var minutes = floor(raw_length/60.0)
		var seconds = int(raw_length) % 60
		var current_play_time = "%02d:%02d" % [minutes,seconds]
		var text_split = current_song_time_label.text.split("/")
		text_split[0] = current_play_time 
		current_song_time_label.text = "%s/%s"%[text_split[0],current_song_length]
		if not is_dragging_slider:
			seek_slider.value = raw_length
		if seek_slider.value == seek_slider.max_value:
			_on_next_music_button_pressed()
		play_pause_music_button.text = "PAUSE"
	else:
		play_pause_music_button.text = "PLAY"

func get_audio_files():
	var music_dir = DirAccess.open(music_folder)
	if music_dir:
		music_dir.list_dir_begin()
		var file_name = music_dir.get_next()
		while file_name != "":
			if not music_dir.current_is_dir() and file_name.ends_with(extention_filter) :
				var full_path = music_folder + "/"+ file_name
				var split_name = file_name.split(extention_filter)
				music_name = split_name[0]
				current_music[total_id_song] = {"song_name":music_name, "song_path":full_path}
				total_id_song += 1
			file_name = music_dir.get_next()
	else:
		push_error("Failed to open Directory")

func extract_metadata():
	var song_id = 0
	while song_id < total_id_song:
		var song = current_music[song_id]["song_path"]
		var file = FileAccess.get_file_as_bytes(song)
		var sound = AudioStreamMP3.new()
		sound.data = file
		
		var tagReader := MP3ID3Tag.new()
		tagReader.stream = sound
		var artist = tagReader.getArtist()
		var album = tagReader.getAlbum()
		var year = tagReader.getYear()
		
		current_music[song_id]["song_artist"] = artist
		current_music[song_id]["song_album"] = album
		current_music[song_id]["song_release_year"] = year
		
		if not DirAccess.dir_exists_absolute(song_cover_cache):
			DirAccess.make_dir_recursive_absolute(song_cover_cache)
		var cover_name = "%s.png" % str(song_id)
		var cover_path = song_cover_cache + cover_name
		var pic: Image = tagReader.getAttachedPicture()
		pic.save_png(cover_path)
		current_music[song_id]["song_cover_path"] = cover_path
		
		song_id += 1

func make_button_songs_container(song_id):
	var song_name = current_music[song_id]['song_name']
	
	var ViewButton = Panel.new()
	songs_container.add_child(ViewButton)
	ViewButton.custom_minimum_size = Vector2(1000.0,90.0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	ViewButton.add_child(margin)
	
	var split_container = HBoxContainer.new()
	margin.add_child(split_container)
	
	var cover = current_music[song_id]["song_cover_path"]
	var music_pic = TextureRect.new()
	split_container.add_child(music_pic)
	music_pic.custom_minimum_size = Vector2(116.0,82.0)
	music_pic.expand_mode = music_pic.EXPAND_IGNORE_SIZE
	load_cover_image(cover,music_pic)
	
	var song_label = Label.new()
	split_container.add_child(song_label)
	song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	song_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	song_label.text = song_name
	
	var button = Button.new()
	button.show_behind_parent = true
	ViewButton.add_child(button,false,Node.INTERNAL_MODE_BACK)
	button.name = song_name
	button.custom_minimum_size = Vector2(1010.0,90.0)
	button.pressed.connect(func(): play_song(song_id),set_current_queue("homepage"))
	button.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)

func make_button_playlists_container(playlist_id):
	var playlist_name = playlists[playlist_id]["playlist_name"]
	
	var ViewButton = Panel.new()
	playlists_container.add_child(ViewButton)
	ViewButton.custom_minimum_size = Vector2(168.0,50.0)
	
	var playlist_label = Label.new()
	ViewButton.add_child(playlist_label)
	playlist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	playlist_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	playlist_label.text = playlist_name
	
	var button = Button.new()
	button.show_behind_parent = true
	ViewButton.add_child(button,false,Node.INTERNAL_MODE_BACK)
	button.custom_minimum_size = Vector2(168.0,50.0)
	button.pressed.connect(func(): open_playlist(playlist_id))

func make_button_playlist_songs(playlist_id,song_id):
	var song = playlists[playlist_id]["songs"][song_id]
	
	var split = HBoxContainer.new()
	playlist_songs_container.add_child(split)
	
	var ViewButton = Panel.new()
	split.add_child(ViewButton)
	ViewButton.custom_minimum_size = Vector2(727.0,90.0)
	
	var remove_button = Button.new()
	split.add_child(remove_button)
	remove_button.text = "Remove"
	remove_button.custom_minimum_size = Vector2(71.0,80.0)
	remove_button.pressed.connect(func(): remove_song_from_playlist(playlist_id,song_id))
	
	var split_container = HBoxContainer.new()
	ViewButton.add_child(split_container)
	
	var cover = song["song_cover_path"]
	var music_pic = TextureRect.new()
	split_container.add_child(music_pic)
	music_pic.custom_minimum_size = Vector2(130.0,82.0)
	music_pic.expand_mode = music_pic.EXPAND_IGNORE_SIZE
	load_cover_image(cover,music_pic)
	
	var song_label = Label.new()
	split_container.add_child(song_label)
	song_label.custom_minimum_size = Vector2(592.0,20.0)
	song_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	song_label.text = song["song_name"]
	song_label.clip_text = true
	
	var button = Button.new()
	button.show_behind_parent = true
	ViewButton.add_child(button,false,Node.INTERNAL_MODE_BACK)
	button.custom_minimum_size = Vector2(727.0,90.0)
	button.pressed.connect(func(): play_song(song_id),set_current_queue("playlist",playlist_id))
	button.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)

func make_button_playlist_add_song(song_id):
	var song = current_music[song_id]
	
	var split = HBoxContainer.new()
	availabel_songs_container.add_child(split)
	
	var view_panel = Panel.new()
	split.add_child(view_panel)
	view_panel.custom_minimum_size = Vector2(860.0,90.0)
	
	var add = CheckBox.new()
	split.add_child(add)
	add.custom_minimum_size = Vector2(20.0,90.0)
	add.toggled.connect(func(toggled_on): add_song_playlist_array(toggled_on,song_id) )
	
	var view_split = HBoxContainer.new()
	view_panel.add_child(view_split)
	
	var cover = current_music[song_id]["song_cover_path"]
	var music_pic = TextureRect.new()
	view_split.add_child(music_pic)
	music_pic.custom_minimum_size = Vector2(130.0,82.0)
	music_pic.expand_mode = music_pic.EXPAND_IGNORE_SIZE
	load_cover_image(cover,music_pic)
	
	var song_label = Label.new()
	view_split.add_child(song_label)
	song_label.custom_minimum_size = Vector2(722.0,20.0)
	song_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	song_label.text = song["song_name"]
	song_label.clip_text = true

func play_song(song_id):
	current_id_song = song_id
	var song_name = current_music[song_id]['song_name']
	current_song_name_label.stop_scroll()
	current_song_name_label.text = song_name
	current_song_name_label.check_and_scroll()
	var song = current_music[song_id]["song_path"]
	var file = FileAccess.open(song,FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	music_player.stream = sound
	var raw_length = sound.get_length()
	var minutes = floor(raw_length/60.0)
	var seconds = int(raw_length) % 60
	var song_length = "%02d:%02d" % [minutes,seconds]
	var text_split = current_song_time_label.text.split("/")
	text_split[1] = song_length
	current_song_time_label.text = "0:00/%s"%text_split[1]
	current_song_length = text_split[1]
	seek_slider.max_value =raw_length
	var cover = current_music[song_id]["song_cover_path"]
	load_cover_image(cover,current_song_cover)
	music_player.play()
	play_pause_music_button.text = "PAUSE"
	
	load_cover_image(cover,full_song_cover)
	full_cover_title.text = song_name
	full_cover_artist.text  = "Artist: " + current_music[song_id]["song_artist"]
	#full_cover_album.text  = "Album: " + current_music[song_id]["song_album"] 
	full_cover_year.text  = "Year: " + current_music[song_id]["song_release_year"]
	
	for child in current_song_cover.get_children():
		child.queue_free()
	
	var button = Button.new()
	button.show_behind_parent = true
	current_song_cover.add_child(button,false,Node.INTERNAL_MODE_BACK)
	button.custom_minimum_size = Vector2(116.0,82.0)
	button.pressed.connect(func(): show_full_current_details())

func load_cover_image(cover_path,image_rect):
	var img = Image.new()
	img.load(cover_path)
	var texture = ImageTexture.create_from_image(img)
	image_rect.texture = texture

func open_playlist(playlist_id):
	current_playlist_id = playlist_id
	manage_playlist_panel.visible = true
	update_songs_in_playlist(playlist_id)

func show_full_current_details():
	if full_current_song_panel.visible == false:
		full_current_song_panel.visible = true
	else:
		full_current_song_panel.visible = false

func set_current_queue(where: String, playlist_id = -1):
	current_queue = []
	if where == "homepage":
		current_queue = current_music.keys().duplicate(true)
	elif where == "playlist" and playlist_id != -1:
		var playlist = playlists[playlist_id]["songs"]
		current_queue = playlist.keys().duplicate(true)
	#if shuffle_on:
		#current_queue.shuffle()

func seek(value):
	music_player.seek(value)

func add_song_playlist_array(pressed,song_id):
	if pressed:
		songs_to_add.append(song_id)
	else:
		songs_to_add.erase(song_id)

func store_app_data():
	var save_dict = {
	"song_folder_path": music_folder,
	"playlists": playlists
	}
	
	var file = FileAccess.open(app_data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()

func load_app_data():
	if not FileAccess.file_exists(app_data_path):
		return
	
	var file = FileAccess.open(app_data_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + app_data_path)
		return 
	var json = JSON.parse_string(file.get_as_text())
	if json == null:
		push_error("Failed to parse JSON: " + app_data_path)
		return 
	
	music_folder = json.get("song_folder_path", "")
	#playlists = json.get("playlists", {})
	file.close()

func startup():
	load_app_data()
	print("Music folder: ",music_folder)
	if music_folder == "":
		setup_page.visible = true
	else:
		get_audio_files()
		extract_metadata()
		store_app_data()
		
		current_song_name_label.text = "------------"
		current_song_time_label.text = "0:00/0:00"
		
		for song_id in current_music:
			make_button_songs_container(song_id)
		
		set_page(home_page)

func set_page(panel):
	panel.visible = true
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	
	for page in menu_panels:
		if page != panel:
			page.visible = false
			page.mouse_filter = MOUSE_FILTER_IGNORE 

func update_playlists():
	for child in playlists_container.get_children():
		child.queue_free()
	for id in playlists:
		make_button_playlists_container(id)
	
func update_songs_in_playlist(playlist_id):
	for child in playlist_songs_container.get_children():
		child.queue_free()
	
	if not playlists[playlist_id]["songs"] == {}:
		for song_id in playlists[playlist_id]["songs"]:
			make_button_playlist_songs(playlist_id,song_id)

func remove_song_from_playlist(playlist_id,song_id):
	playlists[playlist_id]["songs"].erase(song_id)
	update_songs_in_playlist(playlist_id)

func update_available_songs_playlist():
	for child in availabel_songs_container.get_children():
		child.queue_free()
	for song in current_music:
		make_button_playlist_add_song(song)

func block_outside_input(node):
	var blocker = ColorRect.new()
	node.add_child(blocker)
	blocker.custom_minimum_size = Vector2(1148.0,644.0)
	blocker.color = Color(0.0, 0.0, 0.0, 0.0) 
	blocker.name = "blocker"
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker_node = blocker

func remove_input_block():
	if blocker_node:
		blocker_node.queue_free()
		blocker_node = null

func _on_path_sel_button_pressed() -> void:
	folder_select.show()

func _on_seek_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		seek(seek_slider.value)
		if not music_player.playing:
			song_paused_at = seek_slider.value
	is_dragging_slider = false

func _on_seek_slider_drag_started() -> void:
	is_dragging_slider = true

func _on_play_pause_music_button_pressed() -> void:
	if music_player.playing:
		var raw_length = music_player.get_playback_position()
		song_paused_at = raw_length
		music_player.stop()
	else :
		if song_paused_at != 0:
			music_player.play(song_paused_at)

func _on_prev_music_button_pressed() -> void:
	var index = current_queue.find(current_id_song)
	if index != 0:
		var to_play = current_queue[index-1]
		play_song(to_play )
	else :
		play_song(current_queue[-1])

func _on_next_music_button_pressed() -> void:
	var index = current_queue.find(current_id_song)
	if index < current_queue.size() - 1:
		var to_play = current_queue[index+1]
		play_song(to_play)
	else:
		play_song(current_queue[0])

func _on_folder_select_dir_selected(dir: String) -> void:
	music_folder = dir
	setup_page.visible = false
	store_app_data()
	startup()

func _on_home_page_button_pressed() -> void:
	set_page(home_page)

func _on_play_lists_button_pressed() -> void:
	set_page(playlists_page)

func _on_settings_button_pressed() -> void:
	set_page(settings_page)

func _on_playlist_create_button_pressed() -> void:
	block_node = $PageContainer/PlaylistsPage/PlaylistControlPanel
	block_outside_input(block_node)
	make_playlist.visible = true
	var id = str(total_id_playlist)
	var text = "Playlist_%s" %id
	playlist_name_input.text = text

func _on_cancel_create_playlist_pressed() -> void:
	make_playlist.visible = false
	remove_input_block()

func _on_confirm_playlist_name_button_pressed() -> void:
	var id = total_id_playlist
	total_id_playlist += 1
	playlists[id] = {"playlist_name": playlist_name_input.text, "songs": {} }
	update_playlists()
	make_playlist.visible = false
	remove_input_block()
	store_app_data()

func _on_playlist_add_song_button_pressed() -> void:
	block_node = $PageContainer/PlaylistsPage/PlaylistControlPanel
	add_song_panel.visible = true
	update_available_songs_playlist()
	block_outside_input(block_node)

func _on_cancel_add_song_button_pressed() -> void:
	add_song_panel.visible = false
	remove_input_block()

func _on_addsel_songs_button_pressed() -> void:
	var playlist = playlists[current_playlist_id]["songs"]
	for id in songs_to_add:
		var song = current_music[id]
		if not playlist.has(id):  
			playlist[id] = song
	add_song_panel.visible = false
	remove_input_block()
	update_songs_in_playlist(current_playlist_id)
	songs_to_add = []
	store_app_data()

func _on_playlist_rename_button_pressed() -> void:
	pass # Replace with function body.

func _on_play_list_delete_button_pressed() -> void:
	playlists.erase(current_playlist_id)
	manage_playlist_panel.visible = false
	update_playlists()
	store_app_data()
