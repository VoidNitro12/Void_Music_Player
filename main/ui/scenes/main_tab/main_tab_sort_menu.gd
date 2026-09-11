class_name MainTabSortMenu
extends MenuButton
## Custom MenuButton for the [MainTab]


## Builds a unique drop-down depending on the [param current_section]
func set_sort_type(current_section: AppTool.MainTabSections) -> void:
	var popup: PopupMenu = get_popup()
	popup.clear()

	popup.add_item("Title", MainTab.SortType.TITLE)

	match current_section:
		AppTool.MainTabSections.ALL_SONGS:
			popup.add_item("Artist", MainTab.SortType.ARTIST)
		AppTool.MainTabSections.ALBUMS:
			popup.add_item("Artist", MainTab.SortType.ARTIST)
		AppTool.MainTabSections.PLAYLISTS:
			pass
		_:
			AppEvents.log_error.emit(
				AppTool.LogLevels.ERROR,
				"Invalid Option for scetion in MainTabSortMenu.set_sort_type()",
			)
			return
