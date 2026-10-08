class_name FullScreenPlayer
extends Control
## Root UI control for when the app is in fullscreen mode


@export var center_panels: Dictionary[AppTool.FullScreenCenterPanel, Panel]
@export var center_tab: TabContainer
@export var file_tab: FileTab
@export var queue_tab: QueueTab
@export var currently_playing: CurrentlyPlayingBar

## Cache of info pop-ups created
var song_info_windows: Dictionary[EntryData, EntryInfoPopup]


func _ready() -> void:
	file_tab.switch_center_panel.connect(switch_center_panel)
	file_tab.switch_main_tab_section.connect(
		center_panels[AppTool.FullScreenCenterPanel.MAIN].switch_section
	)

	AppEvents.ui.show_entry_info_popup.connect(show_entry_info_popup)
	AppEvents.ui.close_entry_info_popup.connect(close_entry_info_popup)
	AppEvents.ui.show_context_menu.connect(show_context_menu)
	AppEvents.ui.start_loading_wait.connect(show_loading_popup)
	AppEvents.ui.toggle_queue_tab.connect(toggle_queue_tab)
	AppEvents.ui.confirm_action.connect(confirm_action)
	
	# UI ready
	AppEvents.data.rescan_loaded_paths.emit()
	
	AppEvents.ui.refresh_all_tracks.emit()
	AppEvents.ui.refresh_playlist.emit()
	AppEvents.ui.refresh_albums.emit()
	


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
	popup.set_data(data)
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
	context_menu.set_data(data)
	add_child(context_menu)
	context_menu.popup()


## Spawns a [LoadingPopup]
func show_loading_popup() -> void:
	var popup: LoadingPopup = BaseUi.LOADING_POPUP_SCENE.instantiate()
	add_child(popup)
	AppEvents.ui.end_loading_wait.connect(
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
