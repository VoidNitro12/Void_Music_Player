class_name MainTab
extends Panel

enum SortType {
	TITLE,
	ARTIST,
}

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: Button
@export var show_list_btn: Button
@export var sort_by_menu: MainTabSortMenu
@export var sort_id_text: Dictionary[int, String]

@export_group("Item Section")
@export var tab_containers: Dictionary[AppTool.MainTabSections, HFlowContainer]

var view_type: ContainerEntry.ViewType
var sort_type: SortType:
	set(value):
		if sort_type != value:
			sort_type = value
			sort_current_entry()

var current_section: AppTool.MainTabSections


func _ready() -> void:
	current_section = AppTool.MainTabSections.ALL_SONGS
	
	show_grid_btn.pressed.connect(change_view_type.bind(true))
	show_list_btn.pressed.connect(change_view_type.bind(false))
	change_view_type(false)
	
	sort_by_menu.set_sort_type(AppTool.MainTabSections.ALL_SONGS)
	var sort_by_menu_popup: PopupMenu = sort_by_menu.get_popup()
	sort_by_menu_popup.id_pressed.connect(sort_by_menu_id_option)

	AppEvents.all_tracks_set.connect(fill_all_tracks_container)
	AppEvents.all_albums_set.connect(fill_albums_container)


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
				push_error("Unexpected Type %s found in an entry container" % child.get_class())
				continue

			child.change_view_type(view_type)


func switch_section(to: AppTool.MainTabSections) -> void:
	for section: AppTool.MainTabSections in tab_containers.keys():
		tab_containers[section].visible = (section == to)
	current_section = to
	sort_by_menu.set_sort_type(to)


func add_entry(section: AppTool.MainTabSections, data: EntryData, id: int = -1) -> void:
	var entry: ContainerEntry = AppState.CONTAINER_ENTRY_SCENE.instantiate()
	entry.set_data(RequestObj.new(data, section, id))
	entry.change_view_type(view_type)
	tab_containers[section].add_child(entry)


func fill_all_tracks_container() -> void:
	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.ALL_SONGS].get_children():
		child.queue_free()
	
	for song: Song in AppState.all_tracks:
		add_entry(AppTool.MainTabSections.ALL_SONGS, song)
	sort_by_menu.set_sort_type(current_section)

func fill_albums_container() -> void: 
	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.ALBUMS].get_children():
		child.queue_free()
	
	
	
	for album: Album in AppState.albums:
		add_entry(AppTool.MainTabSections.ALBUMS, album, album.id)
	sort_by_menu.set_sort_type(current_section)

func sort_by_menu_id_option(id: int) -> void:
	if not sort_id_text.has(id):
		push_warning("No setup text for an id of \"%s\". Using an empty string " % id)
		sort_id_text[id] = ""

	match id:
		SortType.TITLE:
			sort_by_menu.text = sort_id_text[id]
		SortType.ARTIST:
			sort_by_menu.text = sort_id_text[id]
		_:
			push_error("Invalid Id for sort options")

	sort_type = id as SortType


func sort_current_entry() -> void:
	var sort_rule: Callable
	match sort_type:
		SortType.TITLE:
			sort_rule = func(a: ContainerEntry, b: ContainerEntry) -> bool:
				return a.entry_data.title.to_lower() < b.entry_data.title.to_lower()
		SortType.ARTIST:
			# artist only shows if its a Song or Album
			sort_rule = func(a: ContainerEntry, b: ContainerEntry) -> bool:
				return a.entry_data.artist.to_lower() < b.entry_data.artist.to_lower()
		_:
			push_error("Invalid Option")
			return

	var container: HFlowContainer = tab_containers[current_section]
	var children: Array[Node] = container.get_children().duplicate()
	children.sort_custom(sort_rule)

	for i: int in range(children.size()):
		container.move_child(children[i], i)
