class_name ActionOverlay
extends Panel
## Simple non intrusive overlay to prompt a possible action

# being hardcoded as only main tab uses this to show empty sections
enum Actions {
	EMPTY_ALL_TRACKS_SECTION,
	EMPTY_ALBUMS_SECTION,
	EMPTY_PLAYLISTS_SECTION,
	EMPTY_PLAYLIST,
}

@export var icon: TextureRect

@export var msg_label: Label

@export var action_btn: LinkButton

var _btn_effect: Callable = func()->void: return


func _ready() -> void:
	action_btn.pressed.connect(_on_btn_pressed)


func set_data(
	section: AppTool.MainTabSections,
	origin: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS,
) -> void:
	var action: Actions
	match section:
		AppTool.MainTabSections.ALL_SONGS:
			action = Actions.EMPTY_ALL_TRACKS_SECTION
		AppTool.MainTabSections.ALBUMS:
			action = Actions.EMPTY_ALBUMS_SECTION
		AppTool.MainTabSections.PLAYLISTS:
			action = Actions.EMPTY_PLAYLISTS_SECTION
		AppTool.MainTabSections.PACK:
			match origin:
				AppTool.MainTabSections.ALBUMS:
					return
				AppTool.MainTabSections.PLAYLISTS:
					action = Actions.EMPTY_PLAYLIST
				_:
					return
		_:
			return
	_set_up(action)


func _set_up(action: Actions) -> void:
	match action:
		Actions.EMPTY_ALL_TRACKS_SECTION:
			msg_label.text = "No Songs found"
			action_btn.text = "Scan for songs"
			_btn_effect = func() -> void:
				AppEvents.redirect.to_file_scanning.emit()
		Actions.EMPTY_ALBUMS_SECTION:
			msg_label.text = "No Albums found"
			action_btn.text = ""
			_btn_effect = func() -> void:
				return
		Actions.EMPTY_PLAYLISTS_SECTION:
			msg_label.text = "No Playlists found"
			action_btn.text = "Create Playlist"
			_btn_effect = func() -> void:
				AppEvents.redirect.to_playlist_creation.emit()
		Actions.EMPTY_PLAYLIST:
			msg_label.text = "No Songs in Playlist"
			action_btn.text = "Add Songs"
			_btn_effect = func() -> void:
				AppEvents.redirect.to_playlist_edit_songs.emit()
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"Invalid action value of %d in Action overlay setup" % action,
			)

func  _on_btn_pressed()-> void: 
	if _btn_effect.is_valid():
		_btn_effect.call()
