class_name FullScreenPlayer
extends Control
## Root UI control for when the app is in fullscreen mode

const CONTAINER_ENTRY_SCENE: PackedScene = preload(
	"res://main/ui/scenes/main_tab/ContainerEntry.tscn"
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

@export var center_panels: Dictionary[AppTool.FullScreenCenterPanel, Panel]
@export var file_tab: FileTab
@export var queue_tab: Panel

## Cache of info pop-ups created
var song_info_windows: Dictionary[EntryData, EntryInfoPopup]


func _ready() -> void:
	file_tab.switch_center_panel.connect(switch_center_panel)
	file_tab.switch_main_tab_section.connect(
		center_panels[AppTool.FullScreenCenterPanel.MAIN].switch_section
	)

	AppEvents.show_entry_info_popup.connect(show_entry_info_popup)
	AppEvents.close_entry_info_popup.connect(close_entry_info_popup)
	AppEvents.show_context_menu.connect(show_context_menu)


## Switches the center panel between [MainTab] and [SettingsTab]
# BUG: Switching both items in a HSplitContainer causes messy behaviour and force pushes [QueueTab]
func switch_center_panel(to: AppTool.FullScreenCenterPanel) -> void:
	for key: AppTool.FullScreenCenterPanel in center_panels.keys():
		center_panels[key].visible = (key == to)


## Creates an info popup for an entry data's details
func show_entry_info_popup(data: RequestObj) -> void:
	var entry_data: EntryData = data.entry_data
	if song_info_windows.has(entry_data):
		return

	var popup: EntryInfoPopup = FullScreenPlayer.ENTRY_INFO_POPUP_SCENE.instantiate()
	popup.set_data(data)
	add_child(popup)
	song_info_windows[entry_data] = popup


## Closes an info popup for an entry data's details
func close_entry_info_popup(entry_data: EntryData) -> void:
	if not song_info_windows.has(entry_data):
		return

	var popup: EntryInfoPopup = song_info_windows[entry_data]
	song_info_windows.erase(entry_data)
	remove_child(popup)
	popup.queue_free()


##  Shows a context menu at the mouse's current position
# BUG: Doesn’t free itself upon exit (clicking outside its bounds)
func show_context_menu(data: RequestObj) -> void:
	var context_menu: ContextMenu = FullScreenPlayer.CONTEXT_MENU_POPUP_SCENE.instantiate()
	context_menu.position = get_global_mouse_position()
	context_menu.set_data(data)
	add_child(context_menu)
	context_menu.popup()
