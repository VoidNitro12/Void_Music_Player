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
