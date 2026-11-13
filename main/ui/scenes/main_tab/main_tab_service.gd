class_name MainTabService
extends RefCounted

## Logic helpers for [MainTab]

var _sort_id_text: Dictionary[ContainerEntry.SortType, String]

var _sort_by_menu: MainTabSortMenu

var _bus: EventBus

var _library: Library

# Look ups for easily changing the current selected song entry and rendering
var _all_tracks_songs_lookup: Dictionary[int, ContainerEntry]
var _albums_lookup: Dictionary[int, ContainerEntry]
var _playlists_lookup: Dictionary[int, ContainerEntry]
var _packed_section_lookup: Dictionary[int, ContainerEntry]

## The display type all containers are adopting
var view_type: ContainerEntry.ViewType

## The current [SortType] being used by all containers
var sort_type: ContainerEntry.SortType:
	set(value):
		if sort_type != value:
			sort_type = value
			sort_type_changed.emit()

## The current section being displayed
var current_section: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS

## The id of the current entry being displayed, set to -1 if its not a single entry and instead
## a view of a [Library]'s contents
var current_source_id: int

# only relevant if current section is pack
var current_origin: AppTool.MainTabSections = AppTool.MainTabSections.ALL_SONGS

signal sort_type_changed

func set_up_dependencies(
		bus: EventBus,
		library: Library,
		sort_menu: MainTabSortMenu,
		sort_id_text: Dictionary[ContainerEntry.SortType, String]) -> void:
	_bus = bus
	_library = library
	_sort_by_menu = sort_menu
	_sort_id_text = sort_id_text

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
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.ERROR,
					"Invalid Option for _service.sort_type in MainTab.sort_entry()",
			)
			var empty: Array[int] = []
			return empty

	var sorted_keys: Array[int]
	sorted_keys.assign(wanted.keys())
	sorted_keys.sort_custom(sort_rule)
	return sorted_keys

func sort_by_menu_id_option(id: int) -> void:
	var id_text: String
	if not _sort_id_text.has(id):
		_bus.data.log_error.emit(
				ErrorLogger.LogLevel.WARN,
				"No setup text for an id of \"%d\". Using an empty string " % id,
		)
		id_text = ""
	else:
		id_text = _sort_id_text[id]

	match id:
		ContainerEntry.SortType.ALPHA_TITLE:
			_sort_by_menu.text = id_text
		ContainerEntry.SortType.ALPHA_ARTIST:
			_sort_by_menu.text = id_text
		_:
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.ERROR,
					"Invalid Id %d for sort options in MainTab" % id,
			)
			return

	sort_type = id as ContainerEntry.SortType


func get_source_for_section(
		section: AppTool.MainTabSections,
		source_id: int=-1,
		origin: AppTool.MainTabSections=AppTool.MainTabSections.ALL_SONGS,
) -> Dictionary:
	match section:
		AppTool.MainTabSections.ALL_SONGS:
			return _library.get_all_tracks()
		AppTool.MainTabSections.ALBUMS:
			return _library.get_all_albums()
		AppTool.MainTabSections.PLAYLISTS:
			return _library.get_all_playlists()
		AppTool.MainTabSections.PACK:
			var source: Dictionary
			if origin == AppTool.MainTabSections.PLAYLISTS:
				source = _library.get_songs_from_playlist(source_id)
			elif origin == AppTool.MainTabSections.ALBUMS:
				source = _library.get_songs_from_album(source_id)
			else:
				_bus.data.log_error.emit(
						ErrorLogger.LogLevel.ERROR,
						"Invalid origin of %s for a section od type PACK in " +
								"_get_source_for_section()"
								% AppTool.MainTabSections.keys()[origin],
				)
			return source
		_:
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.ERROR,
					"Invalid section option for _get_source_for_section() in MainTab. " +
							"returning an empty dictionary",
			)
			return {}

func get_lookup_for_section(section: AppTool.MainTabSections) -> Dictionary[int, ContainerEntry]:
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
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.ERROR,
					"Invalid section option for _get_lookup_for_section() in MainTab. " +
							"returning an empty dictionary",
			)
			return {}

func get_context_type_from_section(section: AppTool.MainTabSections) -> AppTool.ContextType:
	match section:
		AppTool.MainTabSections.ALL_SONGS:
			return AppTool.ContextType.SONG
		AppTool.MainTabSections.PLAYLISTS:
			return AppTool.ContextType.PLAYLIST
		AppTool.MainTabSections.ALBUMS:
			return AppTool.ContextType.ALBUM
		_:
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.WARN,
					"No equivalent context type for section of type \"%s\". " +
							"Returning AppTool.ContextType.SONG"
							% AppTool.MainTabSections.keys()[section],
			)
			return AppTool.ContextType.SONG