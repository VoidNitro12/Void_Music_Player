class_name DataView
extends SceneBase

## Sectioned containers to place items
enum SECTION{
	RECENTS,
	ALL_ENTRIES
}

## Panel containers that hold read only data or their corresponding Sections
enum ViewPieces{
	PACK_INFO,
	RECENTS,
	ALL_ENTRIES
}

var _current_section: SECTION

@export var root_scroll: ScrollContainer

@export var containers: Dictionary[SECTION, VirtualScroll]

@export var view_pieces: Dictionary[ViewPieces, PanelContainer]

func _configure() -> void:
	super()
	
	for scroll: VirtualScroll in containers.values():
		scroll.set_bus(_bus)

func _ready() -> void:
	#the root should be able to fully scroll down
	containers[SECTION.ALL_ENTRIES].mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	
	# so basically the root should get all scroll inputs till recents and play info if it exists are out of view
	# the the virtually scroll takes input till you scroll back up to its top where it hands back to the root control
	root_scroll.get_v_scroll_bar().value_changed.connect(_root_scroll_handling)
	containers[SECTION.ALL_ENTRIES].get_v_scroll_bar().value_changed.connect(_all_entries_scroll_handling)

func render(section: SECTION, data_type: AppTool.ContextType ,fill_data: Array[RequestObj], entry_data_info: ItemData,
		data_detail: Dictionary[String, Dictionary]
		) -> void:
	if data_type == AppTool.ContextType.SONG:
		view_pieces[ViewPieces.PACK_INFO].visible = false
	else:
		view_pieces[ViewPieces.PACK_INFO].visible = true
		
	var container: VirtualScroll = containers[section]
	container.set_data(fill_data, entry_data_info, data_detail)
	
	if section == SECTION.ALL_ENTRIES:
		view_pieces[ViewPieces.ALL_ENTRIES].custom_minimum_size.y = root_scroll.size.y

func _root_scroll_handling(value: float) -> void:
	var v_scroll: VScrollBar = root_scroll.get_v_scroll_bar()
	if value == v_scroll.max_value - v_scroll.page:
		containers[SECTION.ALL_ENTRIES].mouse_filter = MouseFilter.MOUSE_FILTER_PASS

func _all_entries_scroll_handling(value: float) -> void:
	if value == containers[SECTION.ALL_ENTRIES].get_v_scroll_bar().min_value:
		containers[SECTION.ALL_ENTRIES].mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	

func sort_entry(to_sort: Dictionary, sort_type: ContainerEntry.SortType) -> Array[String]:
	var sort_rule: Callable
	match sort_type:
		ContainerEntry.SortType.ALPHA_TITLE:
			sort_rule = func(a: String, b: String) -> bool:
				return to_sort[a].title.to_lower() < to_sort[b].title.to_lower()
		ContainerEntry.SortType.ALPHA_ARTIST:
			# artist only shows up in the menu popup if its a Song or Album
			sort_rule = func(a: String, b: String) -> bool:
				return to_sort[a].artist.to_lower() < to_sort[b].artist.to_lower()
		_:
			_bus.data.log_error.emit(
					ErrorLogger.LogLevel.ERROR,
					"Invalid Option for sort_type in DataView.sort_entry()",
					)
			var empty: Array[String] = []
			return empty

	var sorted_keys: Array[String]
	sorted_keys.assign(to_sort.keys())
	sorted_keys.sort_custom(sort_rule)
	return sorted_keys

func is_empty() -> bool: 
	return containers[SECTION.ALL_ENTRIES].is_empty()
