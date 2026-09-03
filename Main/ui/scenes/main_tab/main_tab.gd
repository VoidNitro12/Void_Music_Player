class_name MainTab
extends Panel

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: Button
@export var show_list_btn: Button
@export var sort_by_menu: MenuButton

@export_group("Item Section")
@export var list_entries_container: VBoxContainer
@export var grid_entries_container: GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
