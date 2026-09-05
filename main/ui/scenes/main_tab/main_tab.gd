class_name MainTab
extends Panel

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: Button
@export var show_list_btn: Button
@export var sort_by_menu: MenuButton

@export_group("Item Section")
@export var tab_containers: Dictionary[AppTool.MainTabSections,HFlowContainer]

var view_type: ContainerEntry.ViewType

func _ready() -> void:
	AppEvents.all_tracks_set.connect(fill_all_tracks_container)
	show_grid_btn.pressed.connect(change_view_type.bind(true))
	show_list_btn.pressed.connect(change_view_type.bind(false))
	change_view_type(false)

func change_view_type(type: bool) -> void:
	var h_separation: int
	var v_separation: int
	
	if type:
		show_list_btn.button_pressed = false
		show_grid_btn.button_pressed = true
		h_separation = 20
		v_separation = 10
		view_type = ContainerEntry.ViewType.GRID
	else:
		show_list_btn.button_pressed = true
		show_grid_btn.button_pressed = false
		h_separation = 4
		v_separation = 4
		view_type = ContainerEntry.ViewType.LIST
	
	for container: HFlowContainer in tab_containers.values():
		container.add_theme_constant_override("h_separation", h_separation)
		container.add_theme_constant_override("v_separation", v_separation)
	
		for child: Node in container.get_children():
			if child is not ContainerEntry:
				push_error("Unexpected Type %s found in entries container"%child.get_class())
				continue
			
			child.change_view_type(view_type)

func switch_section(to: AppTool.MainTabSections) -> void: 
	for section: AppTool.MainTabSections in tab_containers.keys():
		if section == to: 
			tab_containers[section].visible = true
		else:
			tab_containers[section].visible = false

func add_entry(section: AppTool.MainTabSections, data: EntryData ) -> void: 
	var entry: ContainerEntry = AppState.CONTAINER_ENTRY_SCENE.instantiate()
	entry.set_data(data)
	entry.change_view_type(view_type)
	tab_containers[section].add_child(entry)

func fill_all_tracks_container() -> void: 
	for song: Song in AppState.all_tracks:
		add_entry(AppTool.MainTabSections.ALL_SONGS, song)
