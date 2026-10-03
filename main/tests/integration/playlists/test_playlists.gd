extends GutTest

const PLAYLIST_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/playlist_options_popup/PlaylistOptionsPopup.tscn"
)

var test_save_dir: String = "res://main/tests/integration/playlists/test_playlist_save_folder/"
var cover_save_dir: String = "res://main/tests/integration/playlists/test_playlist_cover_folder/"
var test_image_path: String = "res://main/tests/integration/playlists/icon.svg"


func before_each() -> void:
	AppState.playlists.clear()
	AppState.playlist_names.clear()
	# Id managers id tracker is meant to be private and shouldn’t cause issues for any test if not
	# cleared
	gut.p("ran setup", 2)


func test_playlist_creation() -> void:
	var save_system: SaveSystem = SaveSystem.new()

	save_system.set_playlist_save_folder(test_save_dir)

	# Override the current save class
	AppState.save_system = save_system
	AppEvents.data.save_playlist.connect(AppState.save_system.save_playlist)

	var test_name: String = "PlaylistTest"
	var test_description: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do 
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
	quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

	# Simulate the popup
	var popup: PlaylistOptionsPopup = PLAYLIST_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE)
	add_child(popup)

	popup.name_line.text = test_name
	popup.description_edit.text = test_description

	# Not testing choosing a new picture for the cover which should default to
	# "res://assets/icons/default_cover.svg"

	# Not testing addition of songs
	popup.confirm_btn.pressed.emit()

	# Validate
	var check: PackedStringArray = DirAccess.get_files_at(test_save_dir)
	assert_gt(check.size(), 0, "No files found in test folder")
	assert_lt(check.size(), 2, "More than 1 file in the test folder, check clean-ups")

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

		# Clean Up
		DirAccess.remove_absolute(test_save_dir + check[0])

	var check_img: PackedStringArray = DirAccess.get_files_at(cover_save_dir)
	if check_img.size() > 0:
		# Clean up as default cover is saved to the cache
		DirAccess.remove_absolute(cover_save_dir + check_img[0])
	
	popup.free()


func test_playlist_editing() -> void:
	var edit_name: String = "EditedName"
	var edit_description: String = "EditedDescription"

	var playlist: Playlist = _create_dummy_playlist()

	# Simulate the popup
	var popup: PlaylistOptionsPopup = PLAYLIST_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, playlist.id, cover_save_dir)
	add_child(popup)

	popup.name_line.text = edit_name
	popup.description_edit.text = edit_description
	popup.picture_selected(test_image_path)

	# Not testing editing of playlist songs
	popup.confirm_btn.pressed.emit()

	# check save
	var check: PackedStringArray = DirAccess.get_files_at(test_save_dir)
	assert_gt(check.size(), 0, "No files found in test folder")
	assert_lt(check.size(), 2, "More than 1 file in the test folder, check clean-ups")

	if check.size() > 0:
		var file: FileAccess = FileAccess.open(test_save_dir.path_join(check[0]), FileAccess.READ)
		assert_ne(file, null, "Could not open made playlist save for further testing")
		if file != null:
			var parsed: Dictionary
			var dict_check: Variant = JSON.parse_string(file.get_as_text())
			assert_eq(typeof(dict_check), TYPE_DICTIONARY, "Corrupted playlist save")
			if typeof(dict_check) == TYPE_DICTIONARY:
				parsed = dict_check

				assert_eq(parsed.get("title", ""), edit_name)
				assert_eq(parsed.get("description", ""), edit_description)

		# Clean up
		DirAccess.remove_absolute(test_save_dir + check[0])

	var check_img: PackedStringArray = DirAccess.get_files_at(cover_save_dir)
	assert_gt(check_img.size(), 0, "No files found in cover folder")
	assert_lt(check_img.size(), 2, "More than 1 file in the cover folder, check clean-ups")

	if check_img.size() > 0:
		# Clean up
		DirAccess.remove_absolute(cover_save_dir + check_img[0])
	
	popup.free()


func test_playlist_deletion() -> void:
	var playlist: Playlist = _create_dummy_playlist()
	

	var playlist_id: int = playlist.id
	var playlist_name: String = playlist.title
	var playlist_storage_id: String = playlist.storage_id

	# There are like 2 ways to delete a playlist so we're just testing the edit popup delete route

	# Simulate the popup
	var popup: PlaylistOptionsPopup = PLAYLIST_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.EDIT, playlist.id)
	add_child(popup)

	popup.delete_btn.pressed.emit()

	assert_false(AppState.playlists.has(playlist_id), "Playlist was not deleted")
	assert_false(
		AppState.playlist_names.has(playlist_name), "Playlists name was not cleared from set"
	)
	assert_false(
		FileAccess.file_exists(test_save_dir.path_join(playlist_storage_id + ".json")),
		"Playlist was not cleared from disk",
	)
	assert_false(
		FileAccess.file_exists(cover_save_dir.path_join(playlist_storage_id + ".png")),
		"Playlist's cover was not cleared from disk",
	)
	
	popup.free()


func _create_dummy_playlist() -> Playlist:
	var save_system: SaveSystem = SaveSystem.new()
	save_system.set_playlist_save_folder(test_save_dir)

	# Override the current save class
	AppState.save_system = save_system
	AppEvents.data.save_playlist.connect(AppState.save_system.save_playlist)

	# Make dummy playlist
	var playlist: Playlist = Playlist.new()
	playlist.storage_id = "99"
	playlist.id = AppState.id_manager.get_id_from_playlist_storage_id(playlist.storage_id)
	playlist.title = "Dummy"
	playlist.description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do 
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
	quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

	AppState.playlists[playlist.id] = playlist
	AppState.save_system.save_playlist(playlist)

	return playlist
