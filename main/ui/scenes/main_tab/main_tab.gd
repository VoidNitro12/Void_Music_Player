class_name MainTab
extends Panel
## Visual display for found [Song]'s, [Playlist]'s and [Album]'s using [ContainerEntry]

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var show_grid_btn: Button
@export var show_list_btn: Button
@export var sort_by_menu: MainTabSortMenu
@export var add_playlist_btn: Button
@export var edit_playlist_btn: Button
@export var toggle_queue_btn: Button
@export var sort_id_text: Dictionary[ContainerEntry.SortType, String]

@export_group("Item Section")
@export var tab_containers: Dictionary[AppTool.MainTabSections, HFlowContainer]
@export var list_btn_groups: Dictionary[AppTool.MainTabSections, ButtonGroup]
@export var grid_btn_groups: Dictionary[AppTool.MainTabSections, ButtonGroup]

@export var item_sections_tab: TabContainer
@export var library_view_tab: TabContainer

## The display type all containers are adopting
var view_type: ContainerEntry.ViewType

## The current [SortType] being used by all containers
var sort_type: ContainerEntry.SortType:
	set(value):
		if sort_type != value:
			sort_type = value
			_render(current_section, current_source, current_source_id)

## The current section being displayed
var current_section: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS
var current_source: Dictionary
var current_source_id: int

var sources: Dictionary[AppTool.MainTabSections, Dictionary]
# Look ups for easily changing the current selected song entry and rendering
var _all_tracks_songs_lookup: Dictionary[int, ContainerEntry]
var _albums_lookup: Dictionary[int, ContainerEntry]
var _playlists_lookup: Dictionary[int, ContainerEntry]
var _packed_section_lookup: Dictionary[int, ContainerEntry]


func _ready() -> void:
	sources = {
		AppTool.MainTabSections.ALL_SONGS: AppState.all_tracks,
		AppTool.MainTabSections.ALBUMS: AppState.albums,
		AppTool.MainTabSections.PLAYLISTS: AppState.playlists,
	}

	var view_btn_group: ButtonGroup = ButtonGroup.new()
	show_grid_btn.button_group = view_btn_group
	show_grid_btn.pressed.connect(change_view_type.bind(ContainerEntry.ViewType.GRID))
	show_list_btn.button_group = view_btn_group
	show_list_btn.pressed.connect(change_view_type.bind(ContainerEntry.ViewType.LIST))
	show_list_btn.button_pressed = true
	change_view_type(ContainerEntry.ViewType.LIST)

	add_playlist_btn.pressed.connect(_add_playlist)
	edit_playlist_btn.pressed.connect(_edit_playlist.bind(current_source_id))
	toggle_queue_btn.pressed.connect(
		func() -> void:
			AppEvents.ui.toggle_queue_tab.emit(),
	)

	sort_by_menu.set_sort_type(AppTool.MainTabSections.ALL_SONGS)
	var sort_by_menu_popup: PopupMenu = sort_by_menu.get_popup()
	sort_by_menu_popup.id_pressed.connect(_sort_by_menu_id_option)

	search_bar.text_changed.connect(search_entries)

	AppEvents.ui.refresh_all_tracks.connect(_fill_all_tracks_container)
	AppEvents.ui.refresh_albums.connect(_fill_albums_container)
	AppEvents.ui.refresh_playlist.connect(_fill_playlists_container)
	AppEvents.ui.open_packed_entry.connect(open_packed_entry)
	AppEvents.ui.edit_playlist.connect(_edit_playlist)
	AppEvents.data.delete_playlist.connect(_delete_playlist)
	# So when the song advances without a direct click the selected highlight
	# updates
	AppEvents.audio.play_song.connect(_select_entry)

	switch_section(AppTool.MainTabSections.ALL_SONGS)
	resized.connect(_resize)


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
	var container: HFlowContainer = tab_containers[current_section]
	container.add_theme_constant_override("h_separation", h_separation)
	container.add_theme_constant_override("v_separation", v_separation)
	view_type = view
	for entry: ContainerEntry in _get_lookup_for_section(current_section).values():
		entry.change_view_type(view)


## Switches the section the tab is on, hence which container is active
func switch_section(to: AppTool.MainTabSections) -> void:
	match to:
		AppTool.MainTabSections.PACK:
			item_sections_tab.current_tab = 1
		_:
			item_sections_tab.current_tab = 0
			library_view_tab.current_tab = to
			current_source = sources[to] #change_view_type forcefully re-renders containers so this
			#is needed to not go out of sync
			edit_playlist_btn.visible = false

	current_section = to
	sort_by_menu.set_sort_type(to)
	change_view_type(view_type)
	add_playlist_btn.visible = (to == AppTool.MainTabSections.PLAYLISTS)


func sort_entry(wanted: Dictionary) -> Array[int]:
	var sort_rule: Callable
	match sort_type:
		ContainerEntry.SortType.ALPHA_TITLE:
			sort_rule = func(a: int, b: int) -> bool:
				return wanted[a].title.to_lower() < wanted[b].title.to_lower()
		ContainerEntry.SortType.ALPHA_ARTIST:
			# artist only shows up in the menu popup if its a Song or Album
			sort_rule = func(a: int, b: int) -> bool:
				return wanted[a].artist.to_lower() < wanted[b].artist.to_lower()
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for sort_type in MainTab.sort_entry()",
			)
			var empty: Array[int] = []
			return empty

	var sorted_keys: Array[int]
	sorted_keys.assign(wanted.keys())
	sorted_keys.sort_custom(sort_rule)
	return sorted_keys


func search_entries(text: String) -> void:
	var lookup: Dictionary[int, ContainerEntry] = _get_lookup_for_section(current_section)
	for child: ContainerEntry in lookup.values():
		if current_section != AppTool.MainTabSections.PLAYLISTS:
			# Search both title and artist on Songs and Albums
			child.visible = (
				child.in_search(ContainerEntry.SortType.SEARCH_TITLE, text)
				or child.in_search(ContainerEntry.SortType.SEARCH_ARTIST, text)
			)
		else:
			# For Playlists search only the Title
			child.visible = child.in_search(ContainerEntry.SortType.SEARCH_TITLE, text)


## Opens and displays the songs contained in a [Playlist] or [Album]
func open_packed_entry(entry_data: EntryData) -> void:
	if entry_data is Song:
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.ERROR,
			"Attempted to open a packet of type Song",
		)
		return

	var section: AppTool.MainTabSections
	
	if entry_data is Album:
		section = AppTool.MainTabSections.ALBUMS
	else:
		section = AppTool.MainTabSections.PLAYLISTS

	_render(AppTool.MainTabSections.PACK, entry_data.songs, entry_data.id, section)

	edit_playlist_btn.visible = (
		current_section == AppTool.MainTabSections.PLAYLISTS and entry_data is Playlist
	)
	switch_section(AppTool.MainTabSections.PACK)

# origin is simply for pack renders where all main tab lookups need the pack tab enum while the 
# request object needs the actual tab to get the context
func _render(
	section: AppTool.MainTabSections,
	wanted: Dictionary,
	source_id: int,
	origin: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS,
) -> void:
	var container: HFlowContainer = tab_containers[section]
	var pool: Dictionary[int, ContainerEntry] = _get_lookup_for_section(section)

	# remove unwanted
	for id: int in pool.keys():
		if not wanted.has(id):
			var entry: ContainerEntry = pool[id]
			container.remove_child(entry)
			entry.queue_free()
			pool.erase(id)

	var sorted_keys: Array[int] = sort_entry(wanted)
	if sorted_keys.is_empty():
		return

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
		var context_section: AppTool.MainTabSections
		if section == AppTool.MainTabSections.PACK:
			context_section = origin
		else:
			context_section = section
		entry.set_data(
			RequestObj.new(wanted[id], _get_context_type_from_section(context_section), source_id),
			false,
			false,
			list_btn_groups[section],
			grid_btn_groups[section],
			true,
		)
		entry.change_view_type(view_type)
		if container.get_child(index) != entry:
			container.move_child(entry, index)
		index += 1

	current_source = wanted
	current_source_id = source_id


func _get_lookup_for_section(section: AppTool.MainTabSections) -> Dictionary[int, ContainerEntry]:
	match section:
		AppTool.MainTabSections.ALL_SONGS:
			return _all_tracks_songs_lookup
		AppTool.MainTabSections.ALBUMS:
			return _albums_lookup
		AppTool.MainTabSections.PLAYLISTS:
			return _playlists_lookup
		AppTool.MainTabSections.PACK:
			return _packed_section_lookup
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid section option for _get_lookup_for_section() in MainTab. 
				returning an empty dictionary",
			)
			return { }


func _get_context_type_from_section(section: AppTool.MainTabSections) -> AppTool.ContextType:
	match section:
		AppTool.MainTabSections.ALL_SONGS:
			return AppTool.ContextType.SONG
		AppTool.MainTabSections.PLAYLISTS:
			return AppTool.ContextType.PLAYLIST
		AppTool.MainTabSections.ALBUMS:
			return AppTool.ContextType.ALBUM
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"No equivalent context type for section of type \"%s\". 
				Returning AppTool.ContextType.SONG"
				% AppTool.MainTabSections.keys()[section],
			)
			return AppTool.ContextType.SONG


func _select_entry(data: RequestObj) -> void:
	var song: Song = data.entry_data
	var entry: ContainerEntry = _get_lookup_for_section(current_section).get(song.id)
	if entry == null:
		return
	entry.set_btn_selection(true)


func _resize() -> void:
	if view_type == ContainerEntry.ViewType.GRID:
		change_view_type(view_type)


func _fill_all_tracks_container() -> void:
	_render(AppTool.MainTabSections.ALL_SONGS, AppState.all_tracks, -1)


func _fill_albums_container() -> void:
	_render(AppTool.MainTabSections.ALBUMS, AppState.albums, -1)


func _fill_playlists_container() -> void:
	_render(AppTool.MainTabSections.PLAYLISTS, AppState.playlists, -1)


func _sort_by_menu_id_option(id: int) -> void:
	var id_text: String
	if not sort_id_text.has(id):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"No setup text for an id of \"%d\". Using an empty string " % id,
		)
		id_text = ""
	else:
		id_text = sort_id_text[id]

	match id:
		ContainerEntry.SortType.ALPHA_TITLE:
			sort_by_menu.text = id_text
		ContainerEntry.SortType.ALPHA_ARTIST:
			sort_by_menu.text = id_text
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Id %d for sort options in MainTab" % id,
			)
			return

	sort_type = id as ContainerEntry.SortType


func _add_playlist() -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE)
	add_child(popup)


func _edit_playlist(playlist_id: int) -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, playlist_id)
	add_child(popup)


func _delete_playlist(_storage_id: String) -> void:
	_fill_playlists_container()

	# playlists can only be deleted from within the playlists section or said playlists pack view
	# hence force the section back to Playlists section after refreshing
	if current_section == AppTool.MainTabSections.PACK:
		switch_section(AppTool.MainTabSections.PLAYLISTS)
