class_name MainTab
extends Panel

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: Button
@export var show_list_btn: Button
@export var sort_by_menu: MenuButton

@export_group("Item Section")
@export var entries_container: HFlowContainer

var view_type: ContainerEntry.ViewType


func _ready() -> void:
	show_grid_btn.pressed.connect(change_view_type.bind(true))
	show_list_btn.pressed.connect(change_view_type.bind(false))
	change_view_type(false)
	

func change_view_type(type: bool) -> void:
	if type:
		show_list_btn.button_pressed = false
		show_grid_btn.button_pressed = true
		entries_container.add_theme_constant_override("h_separation", 20)
		entries_container.add_theme_constant_override("v_separation", 10)
		view_type = ContainerEntry.ViewType.GRID
	else:
		show_list_btn.button_pressed = true
		show_grid_btn.button_pressed = false
		entries_container.add_theme_constant_override("h_separation", 4)
		entries_container.add_theme_constant_override("v_separation", 4)
		view_type = ContainerEntry.ViewType.LIST
	
	for child: Node in entries_container.get_children():
		if child is not ContainerEntry:
			push_error("Unexpected Type %s found in entries container"%child.get_class())
			continue
		
		child.change_view_type(view_type)

func add_entry(song: Song) -> void: 
	var entry: ContainerEntry = AppState.SONG_ENTRY_SCENE.instantiate()
	entry.set_data(song)
	entry.change_view_type(view_type)
	entries_container.add_child(entry)
