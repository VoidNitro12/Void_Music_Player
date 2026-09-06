class_name FullScreenPlayer
extends Control

@export var center_panels: Dictionary[AppTool.FullScreenCenterPanel, Panel]
@export var file_tab: FileTab

var song_info_windows: Dictionary[Song, SongInfoPopup]


func _ready() -> void:
	file_tab.switch_center_panel.connect(switch_center_panel)
	file_tab.switch_main_tab_section.connect(
		center_panels[AppTool.FullScreenCenterPanel.MAIN].switch_section
	)

	AppEvents.show_song_info_popup.connect(show_song_info_popup)
	AppEvents.close_song_info_popup.connect(close_song_info_popup)


func switch_center_panel(to: AppTool.FullScreenCenterPanel) -> void:
	for key: AppTool.FullScreenCenterPanel in center_panels.keys():
		if key == to:
			center_panels[key].visible = true
		else:
			center_panels[key].visible = false


func show_song_info_popup(song: Song) -> void:
	if song_info_windows.has(song) or song == null:
		return

	var popup: SongInfoPopup = AppState.SONG_INFO_POPUP_SCENE.instantiate()
	popup.set_data(song)
	add_child(popup)
	song_info_windows[song] = popup


func close_song_info_popup(song: Song) -> void:
	if not song_info_windows.has(song) or song == null:
		return

	var popup: SongInfoPopup = song_info_windows[song]
	song_info_windows.erase(song)
	remove_child(popup)
	popup.queue_free()
