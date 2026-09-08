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
@export var add_playlist_btn: Button
@export var edit_playlist_btn: Button
@export var sort_id_text: Dictionary[int, String]

@export_group("Item Section")
@export var tab_containers: Dictionary[AppTool.MainTabSections, HFlowContainer]

var view_type: ContainerEntry.ViewType
var sort_type: SortType:
	set(value):
		if sort_type != value:
			sort_type = value
			sort_current_entry()

var current_section: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS

var sub_section_obj: EntryData


func _ready() -> void:
	show_grid_btn.pressed.connect(change_view_type.bind(true))
	show_list_btn.pressed.connect(change_view_type.bind(false))
	change_view_type(false)

	add_playlist_btn.pressed.connect(add_playlist)
	edit_playlist_btn.pressed.connect(edit_playlist)

	sort_by_menu.set_sort_type(AppTool.MainTabSections.ALL_SONGS)
	var sort_by_menu_popup: PopupMenu = sort_by_menu.get_popup()
	sort_by_menu_popup.id_pressed.connect(sort_by_menu_id_option)

	AppEvents.refresh_all_tracks.connect(fill_all_tracks_container)
	AppEvents.refresh_albums.connect(fill_albums_container)
	AppEvents.refresh_playlist.connect(fill_playlists_container)
	AppEvents.open_packed_entry.connect(open_packed_entry)
	
	switch_section(AppTool.MainTabSections.ALL_SONGS)


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
	if to == AppTool.MainTabSections.NONE:
		return

	for section: AppTool.MainTabSections in tab_containers.keys():
		tab_containers[section].visible = (section == to)
	current_section = to
	sort_by_menu.set_sort_type(to)
	add_playlist_btn.visible = (to == AppTool.MainTabSections.PLAYLISTS)
	edit_playlist_btn.visible = false


# specific means you want the entry to register as a type of section while existing in
# desired_section
func add_entry(
	section: AppTool.MainTabSections,
	data: EntryData,
	id: int = -1,
	specific: bool = false,
	desired_section: AppTool.MainTabSections = AppTool.MainTabSections.NONE,
) -> void:
	var entry: ContainerEntry = FullScreenPlayer.CONTAINER_ENTRY_SCENE.instantiate()
	entry.set_data(RequestObj.new(data, section, id))
	entry.change_view_type(view_type)
	if not specific:
		tab_containers[section].add_child(entry)
	else:
		tab_containers[desired_section].add_child(entry)


func fill_all_tracks_container() -> void:
	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.ALL_SONGS].get_children():
		child.queue_free()

	for song: Song in AppState.all_tracks.values():
		add_entry(AppTool.MainTabSections.ALL_SONGS, song)
	sort_by_menu.set_sort_type(current_section)


func fill_albums_container() -> void:
	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.ALBUMS].get_children():
		child.queue_free()

	for album: Album in AppState.albums.values():
		add_entry(AppTool.MainTabSections.ALBUMS, album, album.id)
	sort_by_menu.set_sort_type(current_section)


func fill_playlists_container() -> void:
	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.PLAYLISTS].get_children():
		child.queue_free()

	for playlist: Playlist in AppState.playlists.values():
		add_entry(AppTool.MainTabSections.PLAYLISTS, playlist, playlist.id)
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


func sort_current_entry(
	specific: bool = false,
	section: AppTool.MainTabSections = AppTool.MainTabSections.NONE,
) -> void:
	var sort_rule: Callable
	match sort_type:
		SortType.TITLE:
			sort_rule = func(a: ContainerEntry, b: ContainerEntry) -> bool:
				return a.data_obj.entry_data.title.to_lower() < b \
						.data_obj \
						.entry_data \
						.title \
						.to_lower()
		SortType.ARTIST:
			# artist only shows if its a Song or Album
			sort_rule = func(a: ContainerEntry, b: ContainerEntry) -> bool:
				return a.data_obj.entry_data.artist.to_lower() < b \
						.data_obj \
						.entry_data \
						.artist \
						.to_lower()
		_:
			push_error("Invalid Option")
			return
	var container: HFlowContainer
	if not specific:
		container = tab_containers[current_section]
	else:
		container = tab_containers[section]

	var children: Array[Node] = container.get_children().duplicate()
	children.sort_custom(sort_rule)

	for i: int in range(children.size()):
		container.move_child(children[i], i)


func open_packed_entry(entry_data: EntryData) -> void:
	if entry_data is Song:
		push_error("Attempted to open a packet of type Song")
		return

	# Clear the container first
	for child: Node in tab_containers[AppTool.MainTabSections.NONE].get_children():
		child.queue_free()

	if entry_data is Playlist:
		for song: Song in entry_data.songs:
			add_entry(
				AppTool.MainTabSections.PLAYLISTS,
				song,
				entry_data.id,
				true,
				AppTool.MainTabSections.NONE,
			)
	elif entry_data is Album:
		for song: Song in entry_data.songs:
			add_entry(
				AppTool.MainTabSections.ALBUMS,
				song,
				entry_data.id,
				true,
				AppTool.MainTabSections.NONE,
			)
	for section: AppTool.MainTabSections in tab_containers.keys():
		tab_containers[section].visible = (section == AppTool.MainTabSections.NONE)
	sort_current_entry(true, AppTool.MainTabSections.NONE)
	edit_playlist_btn.visible = (current_section == AppTool.MainTabSections.PLAYLISTS
	and entry_data is Playlist)
	sub_section_obj = entry_data


func add_playlist() -> void:
	var popup: PlaylistOptionsPopup = FullScreenPlayer.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE)
	add_child(popup)


func edit_playlist() -> void:
	var popup: PlaylistOptionsPopup = FullScreenPlayer.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, sub_section_obj.id)
	add_child(popup)
