class_name FileTab
extends Panel

@export var icon_section: PanelContainer
@export var all_songs_btn: Button
@export var albums_btn: Button
@export var playlists_btn: Button
@export var recent_playlists_tree: FileTabTree
@export var settings_btn: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	
