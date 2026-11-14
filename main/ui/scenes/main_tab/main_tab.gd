class_name MainTab
extends SceneBase

## Visual display for found [Song]'s, [Playlist]'s and [Album]'s using [ContainerEntry]

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: IconBtn
@export var show_list_btn: IconBtn
@export var sort_by_menu: MainTabSortMenu
@export var add_playlist_btn: Button
@export var edit_playlist_btn: Button
@export var sort_id_text: Dictionary[ContainerEntry.SortType, String]
@export var action_overlay: ActionOverlay

@export_group("Item Section")
@export var tab_containers: Dictionary[AppTool.MainTabSections, HFlowContainer]
@export var list_btn_groups: Dictionary[AppTool.MainTabSections, ButtonGroup]
@export var grid_btn_groups: Dictionary[AppTool.MainTabSections, ButtonGroup]

@export var item_sections_tab: TabContainer
@export var library_view_tab: TabContainer

var _service: MainTabService

var _library: Library

func set_library(library: Library) -> void:
	_library = library


## Changes the view type of all containers and their children
func change_view_type(view: ContainerEntry.ViewType) -> void:
	var h_separation: int
	var v_separation: int
	match view:
		ContainerEntry.ViewType.LIST:
			h_separation = 4
			v_separation = 10
		ContainerEntry.ViewType.GRID:
			h_separation = 40
			v_separation = 10
	var container: HFlowContainer = tab_containers[_service.current_section]
	container.add_theme_constant_override("h_separation", h_separation)
	container.add_theme_constant_override("v_separation", v_separation)
	_service.view_type = view
	for entry: ContainerEntry in _service.get_lookup_for_section(_service.current_section).values():
		entry.change_view_type(view)


## Switches the section the tab is on, hence which container is active
func switch_section(to: AppTool.MainTabSections) -> void:
	match to:
		AppTool.MainTabSections.PACK:
			item_sections_tab.current_tab = 1
		_:
			item_sections_tab.current_tab = 0
			library_view_tab.current_tab = to
			#is needed to not go out of sync
			edit_playlist_btn.visible = false

	_service.current_section = to
	sort_by_menu.set_sort_type(to)
	change_view_type(_service.view_type)
	add_playlist_btn.visible = (to == AppTool.MainTabSections.PLAYLISTS)
	search_entries(search_bar.text)

func sort_type_changed() -> void:
	_render(_service.current_section, _service.current_source_id)

func search_entries(text: String) -> void:
	var lookup: Dictionary[int, ContainerEntry] = _service.get_lookup_for_section(_service.current_section)
	var num_invis_entries: int = 0
	for child: ContainerEntry in lookup.values():
		if _service.current_section != AppTool.MainTabSections.PLAYLISTS:
			# Search both title and artist on Songs and Albums
			child.visible = (
					child.in_search(ContainerEntry.SortType.SEARCH_TITLE, text)
					or child.in_search(ContainerEntry.SortType.SEARCH_ARTIST, text)
			)
		else:
			# For Playlists search only the Title
			child.visible = child.in_search(ContainerEntry.SortType.SEARCH_TITLE, text)
		if not child.visible:
			num_invis_entries += 1

	if lookup.values().size() == num_invis_entries and not lookup.values().is_empty():
		_action_overlay_visibility(_service.current_section, _service.current_origin, true)
	else:
		_action_overlay_visibility(_service.current_section, _service.current_origin)


## Opens and displays the songs contained in a [Playlist] or [Album]
func open_packed_entry(entry_data: EntryData) -> void:
	if entry_data is Song:
		_bus.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Attempted to open a packet of type Song",
		)
		return

	var section: AppTool.MainTabSections

	if entry_data is Album:
		section = AppTool.MainTabSections.ALBUMS
	else:
		section = AppTool.MainTabSections.PLAYLISTS
		if edit_playlist_btn.pressed.is_connected(_edit_playlist):
			edit_playlist_btn.pressed.disconnect(_edit_playlist)

		edit_playlist_btn.pressed.connect(_edit_playlist.bind(entry_data.id))

	_service.current_origin = section
	_render(AppTool.MainTabSections.PACK, entry_data.id, section)

	edit_playlist_btn.visible = (
			_service.current_section == AppTool.MainTabSections.PLAYLISTS and entry_data is Playlist
	)
	switch_section(AppTool.MainTabSections.PACK)
	_action_overlay_visibility(AppTool.MainTabSections.PACK, section)


func _configure() -> void:
	super()

	_service = MainTabService.new()
	_service.set_up_dependencies(_bus, _library, sort_by_menu, sort_id_text)
	_service.sort_type_changed.connect(sort_type_changed)

	var view_btn_group: ButtonGroup = ButtonGroup.new()
	show_grid_btn.set_bus(_bus)
	show_grid_btn.button_group = view_btn_group
	show_grid_btn.pressed.connect(change_view_type.bind(ContainerEntry.ViewType.GRID))
	show_list_btn.set_bus(_bus)
	show_list_btn.button_group = view_btn_group
	show_list_btn.pressed.connect(change_view_type.bind(ContainerEntry.ViewType.LIST))
	show_list_btn.button_pressed = true
	change_view_type(ContainerEntry.ViewType.LIST)

	add_playlist_btn.pressed.connect(_add_playlist)

	sort_by_menu.set_bus(_bus)
	sort_by_menu.set_sort_type(AppTool.MainTabSections.ALL_SONGS)
	var sort_by_menu_popup: PopupMenu = sort_by_menu.get_popup()
	sort_by_menu_popup.id_pressed.connect(_service.sort_by_menu_id_option)

	search_bar.text_changed.connect(search_entries)

	_bus.ui.refresh_all_tracks.connect(_fill_all_tracks_container)
	_bus.ui.refresh_albums.connect(_fill_albums_container)
	_bus.ui.refresh_all_playlists.connect(_fill_playlists_container)
	_bus.ui.refresh_playlist.connect(
			func(playlist: Playlist) -> void:
				_fill_playlists_container()
				if (
						not _service.current_section == AppTool.MainTabSections.PACK
						and not _service.current_source_id == playlist.id
				):
					return
				open_packed_entry(playlist),
	)
	_bus.ui.open_packed_entry.connect(open_packed_entry)
	_bus.ui.edit_playlist.connect(_edit_playlist)
	_bus.data.delete_playlist.connect(_delete_playlist)
	# So when the song advances without a direct click the selected highlight
	# updates
	_bus.audio.play_song.connect(_select_entry)

	_bus.redirect.to_playlist_creation.connect(
			func() -> void:
				switch_section(AppTool.MainTabSections.PLAYLISTS)
				_add_playlist(),
	)
	_bus.redirect.to_playlist_edit_songs.connect(
			func() -> void:
				edit_playlist_btn.pressed.emit(),
	)
	action_overlay.set_bus(_bus)
	switch_section(AppTool.MainTabSections.ALL_SONGS)
	resized.connect(_resize)


# origin is simply for pack renders where all main tab lookups need the pack tab enum while the
# request object needs the actual tab to get the context
func _render(
		section: AppTool.MainTabSections,
		source_id: int,
		origin: AppTool.MainTabSections=AppTool.MainTabSections.ALL_SONGS,
) -> void:
	
	var container: HFlowContainer = tab_containers[section]
	var pool: Dictionary[int, ContainerEntry] = _service.get_lookup_for_section(section)
	var wanted: Dictionary = _service.get_source_for_section(section, source_id, origin)

	# remove unwanted
	for id: int in pool.keys():
		if not wanted.has(id):
			var entry: ContainerEntry = pool[id]
			container.remove_child(entry)
			entry.queue_free()
			pool.erase(id)

	var sorted_keys: Array[int] = _service.sort_entry(wanted)
	if sorted_keys.is_empty():
		return
	
	var context_section: AppTool.MainTabSections
	if section == AppTool.MainTabSections.PACK:
		context_section = origin
	else:
		context_section = section

	# reuse existing containers or create
	var index: int = 0
	for id: int in sorted_keys:
		var entry: ContainerEntry
		if pool.has(id):
			entry = pool[id]
		else:
			entry = BaseUi.CONTAINER_ENTRY_SCENE.instantiate()
			container.add_child(entry)
			pool[id] = entry
		entry.set_bus(_bus)
		entry.set_data(
				RequestObj.new(wanted[id], _service.get_context_type_from_section(context_section), source_id),
				false,
				false,
				list_btn_groups[section],
				grid_btn_groups[section],
				true,
		)
		entry.change_view_type(_service.view_type)
		if container.get_child(index) != entry:
			container.move_child(entry, index)
		index += 1

	_service.current_source_id = source_id
	_action_overlay_visibility(section, origin)

func _select_entry(data: RequestObj) -> void:
	var song: Song = data.entry_data
	var entry: ContainerEntry = _service.get_lookup_for_section(_service.current_section).get(song.id)
	if entry == null:
		return
	entry.set_btn_selection(true)


func _resize() -> void:
	if _service.view_type == ContainerEntry.ViewType.GRID:
		change_view_type(_service.view_type)


func _fill_all_tracks_container() -> void:
	_render(AppTool.MainTabSections.ALL_SONGS, -1)


func _fill_albums_container() -> void:
	_render(AppTool.MainTabSections.ALBUMS, -1)


func _fill_playlists_container() -> void:
	_render(AppTool.MainTabSections.PLAYLISTS, -1)


func _add_playlist() -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE, _bus, _library)
	add_child(popup)


func _edit_playlist(playlist_id: int) -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, _bus, _library, playlist_id)
	add_child(popup)


func _delete_playlist(_playlist_id: int) -> void:
	_fill_playlists_container()

	# playlists can only be deleted from within the playlists section or said playlists pack view
	# hence force the section back to Playlists section after refreshing
	if _service.current_section == AppTool.MainTabSections.PACK:
		switch_section(AppTool.MainTabSections.PLAYLISTS)
	else:
		_action_overlay_visibility(_service.current_section)


func _action_overlay_visibility(
		section: AppTool.MainTabSections,
		origin: AppTool.MainTabSections=AppTool.MainTabSections.ALL_SONGS,
		search: bool=false,
) -> void:
	var container: HFlowContainer = tab_containers[section]

	if not search:
		if container.get_children().is_empty():
			action_overlay.visible = true
			action_overlay.set_data(section, origin)
		else:
			action_overlay.visible = false
	else:
		action_overlay.visible = true
		action_overlay.set_data(section, origin, true)
