class_name FullScreenPlayer
extends SceneBase
## Root UI control for when the app is in fullscreen mode

@export var center_panels: Dictionary[AppTool.FullScreenCenterPanel, SceneBase]
@export var center_tab: TabContainer
@export var nav_rail: NavRail
@export var queue_tab: QueueTab
@export var currently_playing: CurrentlyPlayingBar
@export var main_tab: MainTab
@export var settings_tab: SettingsTab

## Cache of info pop-ups created
var song_info_windows: Dictionary[EntryData, EntryInfoPopup]

var _library: Library
var _file_scanner: FileScanner

func set_extra_dependacies(library: Library, file_scanner: FileScanner) -> void: 
	_library = library
	_file_scanner = file_scanner

func _configure() -> void:
	nav_rail.switch_center_panel.connect(switch_center_panel)
	nav_rail.switch_main_tab_section.connect(
		center_panels[AppTool.FullScreenCenterPanel.MAIN].switch_section
	)
	
	_bus.ui.show_entry_info_popup.connect(show_entry_info_popup)
	_bus.ui.close_entry_info_popup.connect(close_entry_info_popup)
	_bus.ui.show_context_menu.connect(show_context_menu)
	_bus.ui.start_loading_wait.connect(show_loading_popup)
	_bus.ui.toggle_queue_tab.connect(toggle_queue_tab)
	_bus.ui.confirm_action.connect(confirm_action)
	
	nav_rail.set_bus(_bus)
	main_tab.set_library(_library)
	main_tab.set_bus(_bus)
	settings_tab.lib_section.set_extra_dependacies(_library, _file_scanner)
	settings_tab.set_bus(_bus)
	queue_tab.set_bus(_bus)
	currently_playing.set_bus(_bus)


## Switches the center panel between [MainTab] and [SettingsTab]
func switch_center_panel(to: AppTool.FullScreenCenterPanel) -> void:
	# AppTool.FullScreenCenterPanel matches the indexes of their respective panels under
	# current tab
	center_tab.current_tab = to


func toggle_queue_tab() -> void:
	queue_tab.visible = !queue_tab.visible


## Creates an info popup for an entry data's details
func show_entry_info_popup(data: EntryData) -> void:
	if data == null:
		return

	if song_info_windows.has(data):
		return

	var popup: EntryInfoPopup = BaseUi.ENTRY_INFO_POPUP_SCENE.instantiate()
	popup.set_data(data, _bus)
	add_child(popup)
	song_info_windows[data] = popup


## Closes an info popup for an entry data's details
func close_entry_info_popup(entry_data: EntryData) -> void:
	if not song_info_windows.has(entry_data):
		return

	var popup: EntryInfoPopup = song_info_windows[entry_data]
	song_info_windows.erase(entry_data)
	remove_child(popup)
	popup.queue_free()


##  Shows a context menu at the mouse's current position
func show_context_menu(data: RequestObj) -> void:
	var context_menu: ContextMenu = BaseUi.CONTEXT_MENU_POPUP_SCENE.instantiate()
	context_menu.position = get_global_mouse_position()
	context_menu.set_bus(_bus)
	context_menu.set_data(data)
	add_child(context_menu)
	context_menu.popup()


## Spawns a [LoadingPopup]
func show_loading_popup() -> void:
	var popup: LoadingPopup = BaseUi.LOADING_POPUP_SCENE.instantiate()
	add_child(popup)
	_bus.ui.end_loading_wait.connect(
		close_loading_screen.bind(popup),
		Object.ConnectFlags.CONNECT_ONE_SHOT,
	)


## Kills the current [LoadingPopup]
func close_loading_screen(popup: LoadingPopup) -> void:
	popup.queue_free()


## Shows the [ConfirmDialog] for an action
func confirm_action(action_type: AppTool.ConfirmationType, accept_func: Callable) -> void:
	var confirm_dialog: ConfirmDialog = BaseUi.CONFIRM_DIALOG_POPUP.instantiate()
	add_child(confirm_dialog)
	confirm_dialog.set_data(action_type, accept_func)
