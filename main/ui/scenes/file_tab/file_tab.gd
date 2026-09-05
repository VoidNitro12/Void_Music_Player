class_name FileTab
extends Panel

@export var main_tab_toggles: Dictionary[Button, AppTool.MainTabSections]
@export var icon_section: PanelContainer
@export var all_songs_btn: Button
@export var albums_btn: Button
@export var playlists_btn: Button
@export var recent_playlists_tree: FileTabTree
@export var settings_btn: Button

signal switch_center_panel(to: AppTool.FullScreenCenterPanel)
signal switch_main_tab_section(to: AppTool.MainTabSections)

func _ready() -> void:
	settings_btn.pressed.connect(on_settings_btn_pressed)
	
	for button: Button in main_tab_toggles.keys():
		button.pressed.connect(change_main_section.bind(button))
	
	var root: TreeItem = recent_playlists_tree.create_item()
	
	var header: TreeItem = recent_playlists_tree.create_item(root)
	header.set_text(0, "Recent Playlists")
	header.set_selectable(0,false)
	recent_playlists_tree.hover_exempts.append(header)
	
	
	var dummy_1: TreeItem = recent_playlists_tree.create_item(header)
	dummy_1.set_text(0,"Song 1")
	
	var dummy_2: TreeItem = recent_playlists_tree.create_item(header)
	dummy_2.set_text(0,"Song 2")
	
	var dummy_3: TreeItem = recent_playlists_tree.create_item(header)
	dummy_3.set_text(0,"Song 3")

func change_main_section(btn: Button) -> void: 
	var to: AppTool.MainTabSections = main_tab_toggles[btn]
	for button: Button in main_tab_toggles.keys():
		if button == btn:
			button.button_pressed = true
		else:
			button.button_pressed = false
	
	switch_center_panel.emit(AppTool.FullScreenCenterPanel.MAIN)
	switch_main_tab_section.emit(to)
	settings_btn.button_pressed = false

func on_settings_btn_pressed() -> void: 
	for button: Button in main_tab_toggles.keys():
		button.button_pressed = false
	switch_center_panel.emit(AppTool.FullScreenCenterPanel.SETTINGS)
