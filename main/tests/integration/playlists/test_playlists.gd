extends GutTest


func before_each() -> void:
	gut.p("ran setup", 2)


func test_playlist_creation() -> void:
	var save_syatem: SaveSystem = SaveSystem.new()
	var test_save_dir: String = "res://main/tests/integration/playlists/test_playlist_save_folder/"
	save_syatem.set_playlist_save_folder(test_save_dir)

	# Override the current save class
	AppState.save_system = save_syatem
	AppEvents.data.save_playlist.connect(AppState.save_system.save_playlist)

	var test_name: String = "PlaylistTest"
	var test_description: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do 
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
	quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

	# Simulate the popup
	var popup: PlaylistOptionsPopup = preload(
	"res://main/ui/scenes/playlist_options_popup/PlaylistOptionsPopup.tscn"
	).instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE)
	add_child(popup)

	popup.name_line.text = test_name
	popup.description_edit.text = test_description
	
	# Not testing addition of songs
	
	popup.confirm_btn.pressed.emit()
	
	# Validate
	var check: PackedStringArray = DirAccess.get_files_at(test_save_dir)
	assert_gt(check.size(), 0, "No files found in test folder")
	assert_lt(check.size(), 2, "More than 1 file in the test folder, check cleanups")
	
	if check.size() > 0:
		var file: FileAccess = FileAccess.open(test_save_dir.path_join(check[0]), FileAccess.READ)
		assert_ne(file, null, "Could not open made playlist save for further testing")
		if file != null:
			var parsed: Dictionary
			var dict_check: Variant = JSON.parse_string(file.get_as_text())
			assert_eq(typeof(dict_check), TYPE_DICTIONARY, "Corrupted playlist save")
			if typeof(dict_check) == TYPE_DICTIONARY:
				parsed = dict_check
				
				assert_eq(parsed.get("title", ""), test_name)
				assert_eq(parsed.get("description", ""), test_description)
	
		# Cleanup
		DirAccess.remove_absolute(test_save_dir + check[0])
