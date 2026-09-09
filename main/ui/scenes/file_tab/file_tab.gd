class_name FileTab
extends Panel
## Left tab for switching sections and traversing the app

## Request to switch which center panel is active i.e [MainTab] or [SettingsTab]
signal switch_center_panel(to: AppTool.FullScreenCenterPanel)

## Requests to change the [MainTab]'s section
signal switch_main_tab_section(to: AppTool.MainTabSections)

@export var main_tab_toggles: Dictionary[AppTool.MainTabSections, Button]
@export var icon_section: PanelContainer
@export var recent_playlists_tree: FileTabTree
@export var settings_btn: Button


func _ready() -> void:
	settings_btn.pressed.connect(_on_settings_btn_pressed)

	for button: Button in main_tab_toggles.values():
		button.pressed.connect(_change_main_section.bind(button))

	var root: TreeItem = recent_playlists_tree.create_item()

	var header: TreeItem = recent_playlists_tree.create_item(root)
	header.set_text(0, "Recent Playlists")
	header.set_selectable(0, false)
	recent_playlists_tree.hover_exempts.append(header)

	var dummy_1: TreeItem = recent_playlists_tree.create_item(header)
	dummy_1.set_text(0, "Song 1")

	var dummy_2: TreeItem = recent_playlists_tree.create_item(header)
	dummy_2.set_text(0, "Song 2")

	var dummy_3: TreeItem = recent_playlists_tree.create_item(header)
	dummy_3.set_text(0, "Song 3")


func _change_main_section(btn: Button) -> void:
	var to: AppTool.MainTabSections = main_tab_toggles.find_key(btn)
	for button: Button in main_tab_toggles.values():
		button.button_pressed = (button == btn)

	switch_center_panel.emit(AppTool.FullScreenCenterPanel.MAIN)
	switch_main_tab_section.emit(to)
	settings_btn.button_pressed = false


func _on_settings_btn_pressed() -> void:
	for button: Button in main_tab_toggles.values():
		button.button_pressed = false
	switch_center_panel.emit(AppTool.FullScreenCenterPanel.SETTINGS)
