class_name BaseUi
extends Control

const CONTAINER_ENTRY_SCENE: PackedScene = preload(
	"res://main/ui/scenes/entries/ContainerEntry.tscn"
)
const ENTRY_INFO_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/entry_info_popup/entry_info_popup.tscn"
)
const CONTEXT_MENU_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/context_menu/ContextMenu.tscn"
)
const PLAYLIST_OPTIONS_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/playlist_options_popup/PlaylistOptionsPopup.tscn"
)
const TRACK_SELECT_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/playlist_options_popup/TrackSelectPopup.tscn"
)
const LOADING_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/loading_Popup/LoadingPopup.tscn"
)

const CONFIRM_DIALOG_POPUP: PackedScene = preload(
	"res://main/ui/scenes/confirmation_dialog/confirmation_dialog.tscn"
)

const MINI_ENTRY_SCEME: PackedScene = preload("res://main/ui/scenes/entries/MiniEntry.tscn")

const MINI_PLAYER_SCENE: PackedScene = preload("res://main/ui/scenes/mini_player/MiniPlayer.tscn")

const FULL_SCREEN_SCENE: PackedScene = preload("res://main/ui/scenes/FullScreenPlayer.tscn")

var fullscreen: FullScreenPlayer
var miniplayer: MiniPlayer


func _ready() -> void:
	fullscreen = FULL_SCREEN_SCENE.instantiate()
	add_child(fullscreen)

	miniplayer = MINI_PLAYER_SCENE.instantiate()
	miniplayer.visible = false
	add_child(miniplayer)

	AppEvents.ui.switch_to_mini_player.connect(switch_mini_player_mode)
	AppEvents.ui.change_app_theme.connect(set_app_theme)

	set_app_theme(AppTool.AppThemes.DARK)

	AppEvents.ui.ui_ready.emit()


func switch_mini_player_mode(on: bool) -> void:
	var window: Window = get_window()
	if on:
		miniplayer.set_currently_playing(AppState.audio_handler.context.get_current_context())

		fullscreen.visible = false
		miniplayer.visible = true

		get_tree().root.unresizable = true

		window.mode = Window.MODE_WINDOWED
		window.size = miniplayer.custom_minimum_size

	else:
		fullscreen.currently_playing.set_currently_playing(
			AppState.audio_handler.context.get_current_context()
		)

		fullscreen.visible = true
		miniplayer.visible = false

		get_tree().root.unresizable = false

		window.size = Vector2(1152, 648)
		window.mode = Window.MODE_MAXIMIZED


func set_app_theme(mode: AppTool.AppThemes) -> void:
	var result: Theme = AppState.theme_manager.get_theme(mode)

	if result == null:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Could not get a valid theme of int \'%s\' from ThemeManager"
			% mode,
		)
		return

	theme = result
