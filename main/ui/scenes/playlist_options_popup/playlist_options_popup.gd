class_name PlaylistOptionsPopup
extends Window
## Popup for creating or editing [Playlists]

## Max character amount allowed for a playlists description
const TEXT_EDIT_MAX_LENTH: int = 120

@export var name_line: LineEdit
@export var name_line_count: Label
@export var description_edit: TextEdit
@export var description_edit_count: Label
@export var edit_songs_btn: Button
@export var image: TextureRect
@export var change_image_btn: Button
@export var confirm_btn: Button
@export var delete_btn: Button
@export var pic_dialog: FileDialog

## Songs selected to be used in this playlist
var song_selections: Dictionary[int, Song]

# Used to determine if the cover of the playlist was changed
var _new_cover_path: String = ""


func _ready() -> void:
	close_requested.connect(
		func() -> void:
			self.queue_free(),
	)
	name_line.text_changed.connect(_name_line_changed)
	description_edit.text_changed.connect(_description_edit_changed)
	change_image_btn.pressed.connect(
		func() -> void:
			pic_dialog.visible = true,
	)
	pic_dialog.file_selected.connect(_picture_selected)


## Sets up the container with relevant data
func set_up(edit_type: AppTool.PlaylistEditType, playlist_id: int = -1) -> void:
	match edit_type:
		AppTool.PlaylistEditType.CREATE:
			delete_btn.visible = false
			confirm_btn.text = "Create"
			confirm_btn.pressed.connect(_create_playlist)
		AppTool.PlaylistEditType.EDIT:
			delete_btn.visible = true
			confirm_btn.text = "Save Changes"
			if playlist_id == -1 or not AppState.playlists.has(playlist_id):
				AppEvents.log_error.emit(AppTool.LogLevels.ERROR, "Invalid id provided for an edit")
				return
			var playlist: Playlist = AppState.playlists[playlist_id]
			name_line.text = playlist.title
			delete_btn.text = playlist.description
			image.texture = playlist.cover
			song_selections = playlist.songs
			confirm_btn.pressed.connect(_edit_playlist.bind(playlist))

	edit_songs_btn.pressed.connect(_edit_songs_btn_pressed.bind(playlist_id))


func _picture_selected(path: String) -> void:
	var image_texture: Image = Image.load_from_file(path)
	image.texture = ImageTexture.create_from_image(image_texture)
	_new_cover_path = path


func _name_line_changed(new_text: String) -> void:
	name_line_count.text = "%d/%d" % [new_text.length(), name_line.max_length]


func _description_edit_changed() -> void:
	if description_edit.text.length() > TEXT_EDIT_MAX_LENTH:
		description_edit.text = description_edit.text.left(TEXT_EDIT_MAX_LENTH)
	description_edit_count.text = "%d/%d" % [description_edit.text.length(), TEXT_EDIT_MAX_LENTH]


func _edit_songs_btn_pressed(playlist_id: int) -> void:
	var songs: Dictionary[int, Song]
	if playlist_id != -1:
		var playlist: Playlist = AppState.playlists[playlist_id]
		songs = playlist.songs
	var select: TrackSelectPopup = FullScreenPlayer.TRACK_SELECT_POPUP_SCENE.instantiate()
	select.set_data(songs)
	add_child(select)
	select.selections_confirmed.connect(
		func(update: Dictionary[int, Song]) -> void:
			self.song_selections = update,
	)


func _create_playlist() -> void:
	if AppState.playlist_names.has(name_line.text):
		#TODO should be shown to the user
		AppEvents.log_error.emit(AppTool.LogLevels.WARN, "A playlist with that name already exists")
		return

	if name_line.text.is_empty():
		#TODO should be shown to the user
		AppEvents.log_error.emit(AppTool.LogLevels.WARN, "Playlist name cannot be empty")
		return

	var playlist: Playlist = Playlist.new()
	playlist.title = name_line.text
	playlist.description = description_edit.text
	playlist.id = AppState.playlists.size()
	playlist.songs = song_selections

	playlist.date_dict.assign(Time.get_date_dict_from_system())

	var image_texture: Image = image.texture.get_image()
	var cover_path: String = AppState.PLAYLIST_COVER_CACHE.path_join(
		"%s.png" % str(abs(name_line.text.hash()))
	)
	image_texture.save_png(cover_path)
	playlist.cover_path = cover_path

	AppState.playlists[playlist.id] = playlist
	AppState.playlist_names[name_line.text] = true
	AppEvents.refresh_playlist.emit()
	
	AppEvents.save_app_data.emit()
	ErrorLogger.log_error(AppTool.LogLevels.INFO, "Created New Playlist")
	close_requested.emit()


func _edit_playlist(playlist: Playlist) -> void:
	if playlist.title != name_line.text:
		AppState.playlist_names.erase(playlist.title)
		playlist.title = name_line.text
		AppState.playlist_names[name_line.text] = true

	if playlist.description != description_edit.text:
		playlist.description = description_edit.text

	if not _new_cover_path.is_empty():
		DirAccess.remove_absolute(playlist.cover_path)
		var image_texture: Image = image.texture.get_image()
		var cover_path: String = AppState.PLAYLIST_COVER_CACHE.path_join(
			"%s.png" % str(abs(name_line.text.hash()))
		)
		image_texture.save_png(cover_path)
		playlist.cover_path = cover_path

	playlist.songs = song_selections

	AppEvents.refresh_playlist.emit()

	ErrorLogger.log_error(AppTool.LogLevels.INFO, "Edited Existing Playlist")
	AppEvents.save_app_data.emit()
	close_requested.emit()
	
