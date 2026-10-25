class_name MainTabSortMenu
extends MenuButton
## Custom MenuButton for the [MainTab]

var _bus: EventBus

## Sets up the event bus this object will use for any cross system operations
func set_bus(bus: EventBus)-> void: 
	_bus = bus

## Builds a unique drop-down depending on the [param current_section]
func set_sort_type(current_section: AppTool.MainTabSections) -> void:
	var popup: PopupMenu = get_popup()
	popup.clear()

	popup.add_item("Title", ContainerEntry.SortType.ALPHA_TITLE)

	match current_section:
		AppTool.MainTabSections.ALL_SONGS:
			popup.add_item("Artist", ContainerEntry.SortType.ALPHA_ARTIST)
		AppTool.MainTabSections.ALBUMS:
			popup.add_item("Artist", ContainerEntry.SortType.ALPHA_ARTIST)
		AppTool.MainTabSections.PLAYLISTS:
			pass
		AppTool.MainTabSections.PACK:
			# Add a check for if its an album or playlist pack. Currently harmless but this sort
			# does nothing if its an album
			popup.add_item("Artist", ContainerEntry.SortType.ALPHA_ARTIST)
		_:
			_bus.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid Option for section in MainTabSortMenu.set_sort_type()",
			)
			return
