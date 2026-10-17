class_name NavRail
extends Panel
## Left tab for switching sections and traversing the app

## Request to switch which center panel is active i.e [MainTab] or [SettingsTab]
signal switch_center_panel(to: AppTool.FullScreenCenterPanel)

## Requests to change the [MainTab]'s section
signal switch_main_tab_section(to: AppTool.MainTabSections)

@export var icon_section: PanelContainer
@export var all_songs_btn: IconBtn
@export var albums_btn: IconBtn
@export var playlists_btn: IconBtn
@export var settings_btn: IconBtn


func _ready() -> void:
	settings_btn.pressed.connect(_on_settings_btn_pressed)
	
	all_songs_btn.pressed.connect(_change_main_section.bind(AppTool.MainTabSections.ALL_SONGS))
	
	albums_btn.pressed.connect(_change_main_section.bind(AppTool.MainTabSections.ALBUMS))
	
	playlists_btn.pressed.connect(_change_main_section.bind(AppTool.MainTabSections.PLAYLISTS))
	
	var btn_group: ButtonGroup = ButtonGroup.new()
	for button: IconBtn in [all_songs_btn,albums_btn,playlists_btn,settings_btn]:
		button.button_group = btn_group


	AppEvents.redirect.to_file_scanning.connect(func()->void:
		settings_btn.button_pressed = true
		settings_btn.pressed.emit()
	)


func _change_main_section(to: AppTool.MainTabSections) -> void:
	switch_center_panel.emit(AppTool.FullScreenCenterPanel.MAIN)
	switch_main_tab_section.emit(to)


func _on_settings_btn_pressed() -> void:
	switch_center_panel.emit(AppTool.FullScreenCenterPanel.SETTINGS)
