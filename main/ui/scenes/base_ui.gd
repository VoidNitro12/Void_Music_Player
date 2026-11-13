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

const MINI_ENTRY_SCENE: PackedScene = preload("res://main/ui/scenes/entries/MiniEntry.tscn")

const FULL_SCREEN_SCENE: PackedScene = preload("res://main/ui/scenes/FullScreenPlayer.tscn")

var fullscreen: FullScreenPlayer

var _bus: EventBus

func _ready() -> void:
	# Kinda messes with the purpose of having each class have its own bus and 
	# not reach out, but this is the main scene and im not really sure how to
	# else do this
	_bus = AppState.event_bus
	var library: Library = AppState.library
	var scanner: FileScanner = AppState.file_scanner
	var settings: Settings = AppState.settings
	
	fullscreen = FULL_SCREEN_SCENE.instantiate()
	# For this file and all files with extra dependencies, the extra dependency should be set before the bus is set
	fullscreen.set_extra_dependencies(library, scanner, settings)
	fullscreen.set_bus(_bus)
	add_child(fullscreen)

	_bus.ui.change_app_theme.connect(set_app_theme)

	set_app_theme(AppTool.AppThemes.DARK)

	_bus.ui.ui_ready.emit()


func set_app_theme(mode: AppTool.AppThemes) -> void:
	var result: Theme = AppState.theme_manager.get_theme(mode)

	if result == null:
		_bus.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Could not get a valid theme of int \'%s\' from ThemeManager"
			% mode,
		)
		return

	theme = result
