extends Control
class_name  UIScript
#--------------------------Library -----------------------------------
@onready var all_tracks_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/LibrarySection/VBoxContainer/MarginContainer2/AllTracksButton
@onready var settings_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/SettingsSection/VBoxContainer/MarginContainer2/SettingsButton
@onready var artists_btn: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/LibrarySection/VBoxContainer/MarginContainer3/ArtistsBtn
@onready var playlist_section_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/PlaylistsSection/VBoxContainer/PlaylistSetSection/MarginContainer/PlaylistSectionLabel
@onready var library_section_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/LibrarySection/VBoxContainer/MarginContainer/LibrarySectionLabel

#---------------------------Playlist ---------------------------------
@onready var playlist_set_section: VBoxContainer = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/PlaylistsSection/VBoxContainer/PlaylistSetSection
@onready var new_playlist_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/PlaylistsSection/VBoxContainer/PlaylistSetSection/MarginContainer2/NewPlaylistButton
@onready var playlist_list: VBoxContainer = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/TrackBar/VBoxContainer/PlaylistsSection/VBoxContainer/ScrollContainer/PlaylistList

@onready var make_playlist_container: HBoxContainer = $MakePlaylistContainer
@onready var close_make_playlist_btn: Button = $MakePlaylistContainer/Panel/MarginContainer/VBoxContainer/CloseMakePlaylistBtn
@onready var playlist_name_line: LineEdit = $MakePlaylistContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/PlaylistNameLine
@onready var confirm_add_playlist_btn: Button = $MakePlaylistContainer/Panel/MarginContainer/VBoxContainer/ConfirmAddPlaylistBtn

@onready var playlist_track_controls: Panel = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/PlaylistTrackControls
@onready var edit_songs_playlist: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/PlaylistTrackControls/MarginContainer/HBoxContainer/EditSongsPlaylist
@onready var playlist_rename_song_btn: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/PlaylistTrackControls/MarginContainer/HBoxContainer/PlaylistRenameSongBtn
@onready var playlist_delete_playlist_btn: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/PlaylistTrackControls/MarginContainer/HBoxContainer/PlaylistDeletePlaylistBtn

@onready var add_songs_playlist_container: HBoxContainer = $AddSongsPlaylistContainer
@onready var playlist_add_song_container: VBoxContainer = $AddSongsPlaylistContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/PlaylistAddSongContainer
@onready var rename_playlist_container: HBoxContainer = $RenamePlaylistContainer
@onready var playlist_rename_line: LineEdit = $RenamePlaylistContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/PlaylistRenameLine
@onready var delete_playlist_container: HBoxContainer = $DeletePlaylistContainer

#----------------------------Settings ----------------------------------
@onready var music_library_header: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MlH/MusicLibraryHeader
@onready var playback_header: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MarginContainer/PH/PlaybackHeader
@onready var appearance_header: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MarginContainer2/AH/AppearanceHeader

@onready var ml_line_edit: LineEdit = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MusicFolderOption/MlLineEdit
@onready var ml_browse_btn: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MusicFolderOption/MlBrowseBtn
@onready var ml_scan_btn: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MusicFolderOption/MlScanBtn
@onready var ml_dialogue: FileDialog = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/MusicFolderOption/MlDialogue

@onready var as_check_btn: CheckButton = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/AutoScanOption/ASCheckBtn

@onready var rp_check_btn: CheckButton = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/RemeberPlaybackOption/RPCheckBtn

@onready var accent_option: HBoxContainer = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar/ScrollContainer/MarginContainer/VBoxContainer/AccentOption

#----------------------------Music Controls-------------------------
@onready var track_list: VBoxContainer = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/MarginContainer/ScrollContainer/MarginContainer/TrackList
@onready var shuffle_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer6/HBoxContainer/ShuffleButton
@onready var prev_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer6/HBoxContainer/PrevButton
@onready var play_pause_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer6/HBoxContainer/PlayPauseButton
@onready var next_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer6/HBoxContainer/NextButton
@onready var repeat_button: Button = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer6/HBoxContainer/RepeatButton

#----------------------------Currently Playing------------------------------
@onready var current_cover_image: TextureRect = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer/CurrentCoverImage
@onready var current_song_artist: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer3/CurrentSongArtist
@onready var seek_bar: HSlider = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer4/SeekBar
@onready var current_time_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer5/HBoxContainer/CurrentTimeLabel
@onready var song_lenght_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer5/HBoxContainer/SongLenghtLabel
@onready var current_title_scroll_container: Control = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer2/CurrentTitleScrollContainer
@onready var current_song_title_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/PlayingBar/VBoxContainer/MarginContainer2/CurrentTitleScrollContainer/CurrentSongTitleLabel

#--------------------------Miscelleneous ----------------------------
@onready var settings_bar: Panel = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/SettingsBar
@onready var main_bar: Panel = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar
@onready var status_label: RichTextLabel = $MainPanel/VBoxContainer/InfoBar/HBoxContainer/MarginContainer2/StatusLabel
@onready var status_timer: Timer = $MainPanel/VBoxContainer/InfoBar/HBoxContainer/MarginContainer2/StatusLabel/StatusTimer
@onready var loading_section: HBoxContainer = $LoadingSection
@onready var tracks_count_label: Label = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/Panel/MarginContainer/HBoxContainer/MarginContainer/TracksCountLabel
@onready var track_search_line: LineEdit = $MainPanel/VBoxContainer/LayoutContainer/HSplitContainer/HSplitContainer/MainBar/MainContainer/Panel/MarginContainer/HBoxContainer/TrackSearchLine

var player_theme: Theme = preload("res://UI/Player_Theme.tres")
var scrolling_text_script = preload("res://Main/prev/ScrollingText.gd")
var play_icon = preload("res://UI/Icons/play_icon.png")
var pause_icon = preload("res://UI/Icons/pause_icon.png")

enum Accents{Green,Blue,Purple,Pink,Red,Orange}

var handler = MusicHandler.new()
var PlaylistObject = preload("res://Main/prev/Playlist.gd")
var SongObject = preload("res://Main/prev/Song.gd")


# accent primary = hover
# accent secondary = selected
var accent_colors = {
	Accents.Green: {"primary": Color("#4CAF50"), "secondary": Color("#2E7D32")},
	Accents.Blue: {"primary": Color("#2196F3"), "secondary": Color("#0B5E9E")},
	Accents.Purple: {"primary": Color("#9C27B0"), "secondary": Color("#6A1B9A")},
	Accents.Pink: {"primary": Color("#E91E63"), "secondary": Color("#AD1457")},
	Accents.Red: {"primary": Color("#F44336"), "secondary": Color("#C62828")},
	Accents.Orange: {"primary": Color("#FF9800"), "secondary": Color("#E65100")},
}

#-----------------Settings vars-----------------------
var auto_scan: bool = false
var rem_playback: bool = true
var current_accent: Accents = Accents.Green
#-------------------Data holders-------------------------
# All btns on the libary section barring New Playlist button
var libary_buttons: Array[Button] = []

# Clear before any filling run
var song_buttons: Array[Button] = []

# Shouldn't include New Playlist Button
var playlists_buttons: Array[Button] = []

# for changing accents of said buttons barring the play/pause btn 
var music_control_buttons: Array[Button] = []

var playlist_add_songs: Array[Song]
var current_playlist_btn:  Button
var dragging_seeker: bool = false
var seek_playback: float



# Set and Enforce a Minimum Wdith & Height by adjusting these two values 1024 x 600
# This will not change your overall project settings merely enforce a project settings minimum size 
var min_size = Vector2i(1152, 648)

func _ready() -> void:
	add_child(handler)
	link_signals()
	load_data()
	initialize_ui()
	# Set the minimum size in project settings
	ProjectSettings.set_setting("display/window/size/min_width", min_size.x)
	ProjectSettings.set_setting("display/window/size/min_height", min_size.y)
	
	# Enforce the minimum window size using DisplayServer
	DisplayServer.window_set_min_size(min_size)

func _process(_delta: float) -> void:
	var current_size = DisplayServer.window_get_size()
	# Only enforce minimum size without adjusting the window size if it's above the min size
	if current_size.x < min_size.x or current_size.y < min_size.y:
		DisplayServer.window_set_size(Vector2i(max(current_size.x, min_size.x), max(current_size.y, min_size.y)))
	
	if handler.music_is_playing:
		play_pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		play_pause_button.icon = pause_icon
		if not dragging_seeker:
			seek_bar.value = seek_playback
	else:
		play_pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		play_pause_button.icon = play_icon
	handler.seeker_value = seek_bar.value

func link_signals():
	handler.connect("proccesed_songs", procesed_songs)
	handler.connect("current_details", data_update)
	handler.connect("change_song", toggle_currently_playing)

func initialize_ui():
	libary_buttons = [all_tracks_button,settings_button,artists_btn]
	music_control_buttons = [shuffle_button,next_button,prev_button,repeat_button]
	make_accent_colour_btns()
	accent_change()

#--------------UI init--------------------------
func load_data():
	var data: SaveData = AppState.load_app_data()
	if not data:
		return
	
	handler.all_songs = data.all_songs
	handler.all_playlists = data.all_playlists
	handler.song_paused_at = data.song_paused_at
	handler.total_songs_num = data.all_songs.size()
	handler.total_playlist_num = data.all_playlists.size()
	
	auto_scan = data.auto_scan
	rem_playback = data.rem_playback
	current_accent = data.current_accent
	
	#-------------Update relevant ui-----------------
	as_check_btn.button_pressed = auto_scan
	rp_check_btn.button_pressed = rem_playback
	_on_all_tracks_button_pressed() 

func make_accent_colour_btns()-> void:
	for accent in Accents.keys():
		var index = Accents[accent]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(35,35)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var btn_normal = StyleBoxFlat.new()
		btn_normal.bg_color = accent_colors[index].secondary
		btn_normal.border_color = Color()
		btn_normal.set_border_width_all(1)
		btn_normal.set_corner_radius_all(20)
		btn.add_theme_stylebox_override("normal",btn_normal)
		
		var btn_hover = StyleBoxFlat.new()
		btn_hover.bg_color = accent_colors[index].primary
		btn_hover.border_color = Color()
		btn_hover.set_border_width_all(2)
		btn_hover.set_corner_radius_all(20)
		btn.add_theme_stylebox_override("hover",btn_hover)
		
		var btn_pressed = StyleBoxFlat.new()
		btn_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		btn_pressed.border_color = Color()
		btn_pressed.set_border_width_all(2)
		btn_pressed.set_corner_radius_all(20)
		btn.add_theme_stylebox_override("pressed",btn_pressed)
		
		var btn_hover_pressed = StyleBoxFlat.new()
		btn_hover_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		btn_hover_pressed.border_color = Color()
		btn_hover_pressed.set_border_width_all(2)
		btn_hover_pressed.set_corner_radius_all(20)
		btn.add_theme_stylebox_override("hover_pressed",btn_hover_pressed)
		
		btn.pressed.connect(update_current_accent.bind(index))
		
		accent_option.add_child(btn)

func accent_change() -> void:
	
	#--------------------------Base Changes-----------------------------------
	var button_hover: StyleBoxFlat = player_theme.get_stylebox("hover", "Button")
	button_hover.bg_color = accent_colors[current_accent].primary
	player_theme.set_stylebox("hover", "Button", button_hover)
	
	var button_pressed: StyleBoxFlat = player_theme.get_stylebox("pressed", "Button")
	button_pressed.bg_color = accent_colors[current_accent].secondary
	player_theme.set_stylebox("pressed", "Button", button_pressed)
	
	var button_hover_pressed: StyleBoxFlat = player_theme.get_stylebox("hover_pressed", "Button")
	button_hover_pressed.bg_color = accent_colors[current_accent].primary
	player_theme.set_stylebox("hover_pressed", "Button", button_hover_pressed)
	
	var h_slider_grabber_area: StyleBoxFlat = player_theme.get_stylebox("grabber_area", "HSlider")
	h_slider_grabber_area.bg_color = accent_colors[current_accent].secondary
	player_theme.set_stylebox("grabber_area", "HSlider", h_slider_grabber_area)
	
	var h_slider_grabber_area_highlight: StyleBoxFlat = player_theme.get_stylebox("grabber_area_highlight", "HSlider")
	h_slider_grabber_area_highlight.bg_color = accent_colors[current_accent].primary
	player_theme.set_stylebox("grabber_area_highlight", "HSlider", h_slider_grabber_area_highlight)
	
	var check_box_normal: StyleBoxFlat = player_theme.get_stylebox("normal", "CheckBox")
	check_box_normal.bg_color = accent_colors[current_accent].secondary
	player_theme.set_stylebox("normal", "CheckBox", check_box_normal)
	
	var check_box_hover: StyleBoxFlat = player_theme.get_stylebox("hover", "CheckBox")
	check_box_hover.bg_color = accent_colors[current_accent].primary
	player_theme.set_stylebox("hover", "CheckBox", check_box_hover)
	#------------------------------------Settings/Library Headers---------------------------------
	music_library_header.add_theme_color_override("font_color", accent_colors[current_accent].primary)
	playback_header.add_theme_color_override("font_color", accent_colors[current_accent].primary)
	appearance_header.add_theme_color_override("font_color", accent_colors[current_accent].primary)
	playlist_section_label.add_theme_color_override("font_color", accent_colors[current_accent].primary)
	library_section_label.add_theme_color_override("font_color", accent_colors[current_accent].primary)
	
	#------------------------------------Music Library btns Headers------------------------------
	var ml_btns_normal = StyleBoxFlat.new()
	ml_btns_normal.bg_color = accent_colors[current_accent].secondary
	ml_btns_normal.set_corner_radius_all(5)
	ml_btns_normal.border_color = Color()
	ml_browse_btn.add_theme_stylebox_override("normal", ml_btns_normal)
	ml_scan_btn.add_theme_stylebox_override("normal",ml_btns_normal)
	
	var ml_btns_hover = StyleBoxFlat.new()
	ml_btns_hover.bg_color = accent_colors[current_accent].primary
	ml_btns_hover.set_corner_radius_all(5)
	ml_btns_hover.border_color = Color()
	ml_browse_btn.add_theme_stylebox_override("hover", ml_btns_hover)
	ml_scan_btn.add_theme_stylebox_override("hover",ml_btns_hover)
	
	var ml_btns_pressed = StyleBoxFlat.new()
	ml_btns_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	ml_btns_pressed.set_corner_radius_all(5)
	ml_btns_pressed.border_color = Color()
	ml_browse_btn.add_theme_stylebox_override("pressed", ml_btns_pressed)
	ml_scan_btn.add_theme_stylebox_override("pressed",ml_btns_pressed)
	
	var ml_btns_hover_pressed = StyleBoxFlat.new()
	ml_btns_hover_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	ml_btns_hover_pressed.set_corner_radius_all(5)
	ml_btns_hover_pressed.border_color = Color()
	ml_browse_btn.add_theme_stylebox_override("hover_pressed", ml_btns_hover_pressed)
	ml_scan_btn.add_theme_stylebox_override("hover_pressed",ml_btns_hover_pressed)
	
	#------------------------------------Play/Pause btn---------------------------------
	var play_btn_normal = StyleBoxFlat.new()
	play_btn_normal.bg_color = accent_colors[current_accent].secondary
	play_btn_normal.set_corner_radius_all(35)
	play_pause_button.add_theme_stylebox_override("normal", play_btn_normal)
	
	var play_btn_hover = StyleBoxFlat.new()
	play_btn_hover.bg_color = accent_colors[current_accent].primary
	play_btn_hover.set_corner_radius_all(35)
	play_pause_button.add_theme_stylebox_override("hover", play_btn_hover)
	
	var play_btn_pressed = StyleBoxFlat.new()
	play_btn_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	play_btn_pressed.set_corner_radius_all(35)
	play_pause_button.add_theme_stylebox_override("pressed", play_btn_pressed)
	
	var play_btn_hover_pressed = StyleBoxFlat.new()
	play_btn_hover_pressed.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	play_btn_hover_pressed.set_corner_radius_all(35)
	play_pause_button.add_theme_stylebox_override("hover_pressed", play_btn_hover_pressed)
	
	#-----------------------------Music Control btns---------------------------
	for music_btn: Button in music_control_buttons:
		
		var music_btn_hover = StyleBoxFlat.new()
		music_btn_hover.bg_color = accent_colors[current_accent].primary
		music_btn_hover.set_corner_radius_all(20)
		music_btn.add_theme_stylebox_override("hover", music_btn_hover)
		
		var music_btn_pressed = StyleBoxFlat.new()
		music_btn_pressed.bg_color = accent_colors[current_accent].secondary
		music_btn_pressed.set_corner_radius_all(20)
		music_btn.add_theme_stylebox_override("pressed", music_btn_pressed)
		
		var music_btn_hover_pressed = StyleBoxFlat.new()
		music_btn_hover_pressed.bg_color = accent_colors[current_accent].primary
		music_btn_hover_pressed.set_corner_radius_all(20)
		music_btn.add_theme_stylebox_override("hover_pressed", music_btn_hover_pressed)

#----------------------------------------

func procesed_songs():
	loading_section.visible = false
	save_data()

func data_update(current_play_time: String,playback: float):
	current_time_label.text = current_play_time
	seek_playback = playback

func update_current_accent(accent: Accents)-> void:
	current_accent = accent
	accent_change()
	save_data()

func toggle_currently_playing(song: Song)-> void:
	var song_source: Object
	var target_song: Song
	
	for btn: Button in song_buttons:
		target_song = btn.get_meta("SongData") as Song
		if target_song != song:
			btn.button_pressed = false
		else:
			btn.button_pressed = true
			if btn.has_meta("Source"):
				song_source = btn.get_meta("Source")

	current_cover_image.texture =  song.get_song_cover()
	current_song_title_label.text = song.title
	current_title_scroll_container.stop_marquee()
	current_title_scroll_container.check_and_scroll()
	current_song_artist.text = song.artist
	current_time_label.text = "0:00"
	song_lenght_label.text = song.duration
	seek_bar.max_value = song.raw_length
	handler.play_song(song,song_source)

func toggle_library(btn: Button)-> void:
	song_buttons = []
	for child in track_list.get_children():
		child.queue_free()
	for child in playlist_add_song_container.get_children():
		child.queue_free()
	
	btn.button_pressed = true
	
	for btns: Button in libary_buttons:
		if btns != btn:
			btns.button_pressed = false
	
	for btns: Button in playlists_buttons:
		if btns != btn:
			btns.button_pressed = false
	
	if btn.text != "Settings" and btn.text != "Artists":
		var is_playlist: bool = btn.get_meta("is_playlist", false)
		var playlist_obj: Playlist
		if is_playlist:
			playlist_obj = btn.get_meta("Playlist")
			handler.current_playlist = playlist_obj
			current_playlist_btn = btn
		else:
			handler.current_playlist = null
			current_playlist_btn = null
		build_tracklist(playlist_obj,is_playlist)

func build_tracklist(playlist_obj: Playlist ,playlist_build: bool = false):
	playlist_track_controls.visible = playlist_build
	main_bar.visible = true
	settings_bar.visible = false
	var song_source: Array
	var source: Object
	var track_count: int = 0
	if not playlist_build:
		song_source = handler.all_songs
	else:
		source = playlist_obj
		song_source = playlist_obj.songs 
	
	for entry in song_source:
		track_count += 1
		make_button_track_container(entry,source)
	
	tracks_count_label.text = "%s Tracks"%str(track_count)

func make_button_track_container(song: Song, source: Object)-> void:
	
	var Base = PanelContainer.new()
	var base_stylebox = StyleBoxEmpty.new()
	Base.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Base.custom_minimum_size.y = 50
	Base.name = song.title
	Base.add_theme_stylebox_override("panel", base_stylebox)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Base.add_child(hbox)
	
	#var num_label = Label.new()
	#num_label.text = ""
	#num_label.custom_minimum_size.x = 28
	#num_label.add_theme_font_size_override("font_size",14)
	#hbox.add_child(num_label)
	
	var cover_margin = MarginContainer.new()
	cover_margin.add_theme_constant_override("margin_left", 6)
	hbox.add_child(cover_margin)
	
	var cover = TextureRect.new()
	cover.custom_minimum_size.x = 80
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	#cover.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cover.texture = song.get_song_cover()
	cover_margin.add_child(cover)
	
	var title_margin = MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 7)
	hbox.add_child(title_margin)
	
	var label_vbox = VBoxContainer.new()
	label_vbox.custom_minimum_size.x = 430
	label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label_vbox)
	
	var title_label = Label.new()
	title_label.text = song.title
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_vbox.add_child(title_label)
	
	var artist_label = Label.new()
	artist_label.text = song.artist
	artist_label.add_theme_font_size_override("font_size",12)
	label_vbox.add_child(artist_label)
	
	var duration_label = Label.new()
	duration_label.text = song.duration
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	duration_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(duration_label)
	
	var button = Button.new()
	button.show_behind_parent = true
	button.toggle_mode = true
	#button.name = song_name
	button.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = song.title
	button.set_meta("SongData", song)
	button.set_meta("Source", source)
	button.pressed.connect(func(): toggle_currently_playing(song))
	Base.add_child(button,false,Node.INTERNAL_MODE_BACK)
	song_buttons.append(button)
	
	track_list.add_child(Base)

func make_button_add_songs_container(song: Song, in_playlist: bool = false):
	var Base = PanelContainer.new()
	var base_stylebox = StyleBoxEmpty.new()
	Base.custom_minimum_size.y = 50
	Base.add_theme_stylebox_override("panel", base_stylebox)
	
	var hbox = HBoxContainer.new()
	Base.add_child(hbox)
	
	var cover_margin = MarginContainer.new()
	cover_margin.add_theme_constant_override("margin_left", 6)
	hbox.add_child(cover_margin)
	
	var cover = TextureRect.new()
	cover.custom_minimum_size.x = 80
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	#cover.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cover.texture = song.get_song_cover()
	cover_margin.add_child(cover)
	
	var title_margin = MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 7)
	hbox.add_child(title_margin)
	
	var label_vbox = VBoxContainer.new()
	label_vbox.custom_minimum_size.x = 450
	hbox.add_child(label_vbox)
	
	var title_label = Label.new()
	title_label.text = song.title
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	label_vbox.add_child(title_label)
	
	var artist_label = Label.new()
	artist_label.text = song.artist
	artist_label.add_theme_font_size_override("font_size",12)
	label_vbox.add_child(artist_label)
	
	var check_box = CheckBox.new()
	check_box.button_pressed = in_playlist
	check_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_box.toggled.connect(func(toggled_on): add_song_playlist_array(toggled_on,song) )
	if check_box.button_pressed == true:
		add_song_playlist_array(true,song)
	hbox.add_child(check_box)
	
	playlist_add_song_container.add_child(Base)

func add_song_playlist_array(toggled_on: bool, song: Song):
	if toggled_on:
		playlist_add_songs.append(song)
	else:
		playlist_add_songs.erase(song)

func update_status_label(text: String):
	status_label.text = "[color=yellow]%s[/color]"%text
	
	var timer = status_timer
	timer.wait_time = 7
	timer.one_shot = true
	timer.start()

func reset_status_label():
	status_label.text = ""

# Only searches Song Titles
func track_search(target: String):
	target = target.to_lower()
	if target == "":
		for Base in track_list.get_children():
			Base.visible = true
		return
	
	for Base in track_list.get_children():
		if target not in Base.name.to_lower():
			Base.visible = false
		else:
			Base.visible = true

func save_data():
	AppState.all_playlists = handler.all_playlists
	AppState.all_songs = handler.all_songs
	AppState.auto_scan = auto_scan
	AppState.current_accent = current_accent
	AppState.rem_playback = rem_playback
	AppState.song_paused_at = handler.song_paused_at
	AppState.save_app_data()

#-------------------Connections-----------------------
func _on_settings_button_pressed() -> void:
	settings_bar.visible = true
	main_bar.visible = false
	toggle_library(settings_button)

func _on_all_tracks_button_pressed() -> void:
	toggle_library(all_tracks_button)

func _on_as_check_btn_toggled(toggled_on: bool) -> void:
	auto_scan = toggled_on
	save_data()

func _on_rp_check_btn_toggled(toggled_on: bool) -> void:
	rem_playback = toggled_on
	save_data()

func _on_ml_browse_btn_pressed() -> void:
	ml_dialogue.visible = true

func _on_ml_scan_btn_pressed() -> void:
	if ml_line_edit.text == "":
		update_status_label("No valid directory selected")
		return
	var err: String = handler.scan(ml_line_edit.text)
	if err != "OK":
		update_status_label(err)
		return
	loading_section.visible = true

func _on_ml_dialogue_dir_selected(dir: String) -> void:
	ml_line_edit.text = dir

func _on_status_timer_timeout() -> void:
	reset_status_label()

func _on_new_playlist_button_pressed() -> void:
	make_playlist_container.visible = true
	playlist_name_line.text = ""

func _on_close_make_playlist_btn_pressed() -> void:
	make_playlist_container.visible = false

func _on_confirm_add_playlist_btn_pressed() -> void:
	var playlist_name = playlist_name_line.text
	
	if playlist_name == "":
		update_status_label("Playlist name cannot be empty")
		return
	
	for btn in playlists_buttons:
		if btn.text == playlist_name:
			update_status_label("Another playlist already has this name")
			return
	
	var playlist = handler.add_playlist(playlist_name)
	
	var playlist_btn = Button.new()
	playlist_btn.text = playlist_name
	playlist_btn.toggle_mode = true
	playlist_btn.set_meta("is_playlist", true)
	playlist_btn.set_meta("Playlist", playlist) 
	playlist_btn.pressed.connect(toggle_library.bind(playlist_btn))
	playlist_list.add_child(playlist_btn)
	playlists_buttons.append(playlist_btn)
	make_playlist_container.visible = false

func _on_seek_bar_drag_ended(value_changed: bool) -> void:
	if value_changed:
		handler.seek(seek_bar.value)
		if not handler.music_is_playing:
			handler.song_paused_at = seek_bar.value
	dragging_seeker = false

func _on_seek_bar_drag_started() -> void:
	dragging_seeker = true

func _on_play_pause_button_pressed() -> void:
	handler.pause_play()

func _on_next_button_pressed() -> void:
	handler.next_song()

func _on_prev_button_pressed() -> void:
	handler.prev_song()

func _on_repeat_button_toggled(toggled_on: bool) -> void:
	handler.repeat = toggled_on

func _on_shuffle_button_toggled(toggled_on: bool) -> void:
	handler.shuffle(toggled_on)

func _on_close_add_song_btn_pressed() -> void:
	add_songs_playlist_container.visible = false

func _on_confirm_add_songs_btn_pressed() -> void:
	var valid = handler.edit_songs_playlist(playlist_add_songs)
	if not valid:
		update_status_label("Unable to edit playlist")
		return
	toggle_library(current_playlist_btn)
	add_songs_playlist_container.visible = false
	playlist_add_songs.clear()

func _on_edit_songs_playlist_pressed() -> void:
	add_songs_playlist_container.visible = true
	var in_playlist: bool = false
	
	for song: Song in handler.all_songs:
		in_playlist = handler.current_playlist.songs.has(song)
		make_button_add_songs_container(song, in_playlist)

func _on_track_search_line_text_changed(new_text: String) -> void:
	track_search(new_text)

func _on_playlist_rename_song_btn_pressed() -> void:
	rename_playlist_container.visible = true

func _on_close_rename_playlist_pressed() -> void:
	rename_playlist_container.visible = false

func _on_confirm_playlist_rename_pressed() -> void:
	var playlist_name = playlist_rename_line.text
	
	if playlist_name == "":
		update_status_label("Playlist name cannot be empty")
		return
	
	handler.rename_playlist(playlist_name)
	current_playlist_btn.text = playlist_name
	rename_playlist_container.visible = false

func _on_playlist_delete_playlist_btn_pressed() -> void:
	delete_playlist_container.visible = true

func _on_close_delete_playlist_pressed() -> void:
	delete_playlist_container.visible = false

func _on_confirm_playlist_delete_pressed() -> void:
	playlist_list.remove_child(current_playlist_btn)
	playlists_buttons.erase(current_playlist_btn)
	current_playlist_btn.queue_free()
	
	handler.delete_playlist()
	
	delete_playlist_container.visible = false
	_on_all_tracks_button_pressed()
