class_name MainTab
extends SceneBase

## Visual display for found [Song]'s, [Playlist]'s and [Album]'s using [ContainerEntry]

@export var data_view: DataView

@export_group("Nav Section")
@export var search_bar: LineEdit
@export var sort_by_menu: MainTabSortMenu
@export var add_playlist_btn: Button
@export var edit_playlist_btn: Button
@export var sort_id_text: Dictionary[ContainerEntry.SortType, String]
@export var action_overlay: ActionOverlay

var _service: MainTabService

var _library: Library

func set_library(library: Library) -> void:
	_library = library


## Switches the section the tab is on, hence which container is active
func switch_section(to: AppTool.MainTabSections) -> void:
	_render(to, "")

func sort_type_changed() -> void:
	pass

func search_entries(text: String) -> void:
	var lookup: Dictionary[String, ContainerEntry] = _service.get_lookup_for_section(_service.current_section)
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
	_render(AppTool.MainTabSections.PACK, entry_data.uuid, section)

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

	data_view.set_bus(_bus)

	add_playlist_btn.pressed.connect(_add_playlist)

	sort_by_menu.set_bus(_bus)
	sort_by_menu.set_sort_type(AppTool.MainTabSections.ALL_SONGS)
	var sort_by_menu_popup: PopupMenu = sort_by_menu.get_popup()
	sort_by_menu_popup.id_pressed.connect(_service.sort_by_menu_id_option)

	search_bar.text_changed.connect(search_entries)

	_bus.ui.refresh_main_tab.connect(_refresh_display)
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


# origin is simply for pack renders where all main tab lookups need the pack tab enum while the
# request object needs the actual tab to get the context
func _render(
		section: AppTool.MainTabSections,
		source_id: String,
		origin: AppTool.MainTabSections=AppTool.MainTabSections.ALL_SONGS,
		details: Dictionary[String, Dictionary] = {}
) -> void:
	
	# data_view.render(DataView.SECTION.RECENTS
	# 		, _service.get_context_type_from_section(section)
	# )
	
	var render_data_all_entries: Array[RequestObj] = _service.get_render_data(section, source_id, origin)
	
	data_view.render(DataView.SECTION.ALL_ENTRIES, 
			_service.get_context_type_from_section(section),
			render_data_all_entries,
			ItemData.new(false, false, ButtonGroup.new()),
			details
	)
	
	_service.current_section = section
	_service.current_source_id = source_id
	_service.current_origin = origin
	
	_action_overlay_visibility(section, origin)

func _select_entry(data: RequestObj) -> void:
	var detail: Dictionary[String, Dictionary] = {data.entry_data.uuid:{"selected": true}}
	_render(
			_service.current_section, 
			_service.current_source_id, 
			_service.current_section, 
			detail)


func _refresh_display() -> void:
	_render(
			_service.current_section,
			_service.current_source_id,
			_service.current_section,
	)

func _add_playlist() -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE, _bus, _library)
	add_child(popup)


func _edit_playlist(playlist_id: String) -> void:
	var popup: PlaylistOptionsPopup = BaseUi.PLAYLIST_OPTIONS_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, _bus, _library, playlist_id)
	add_child(popup)


func _delete_playlist(_playlist_id: String) -> void:
	_refresh_display()

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
	if not search:
		if data_view.is_empty():
			action_overlay.visible = true
			action_overlay.set_data(section, origin)
		else:
			action_overlay.visible = false
	else:
		action_overlay.visible = true
		action_overlay.set_data(section, origin, true)
