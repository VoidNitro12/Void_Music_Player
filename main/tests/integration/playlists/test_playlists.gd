extends GutTest

const PLAYLIST_POPUP_SCENE: PackedScene = preload(
	"res://main/ui/scenes/playlist_options_popup/PlaylistOptionsPopup.tscn"
)

var test_save_dir: String = "res://main/tests/integration/playlists/test_playlist_save_folder/"
var cover_save_dir: String = "res://main/tests/integration/playlists/test_playlist_cover_folder/"
var test_image_path: String = "res://main/tests/integration/playlists/icon.svg"


func before_each() -> void:
	for test_folder_path: String in [test_save_dir, cover_save_dir]:
		if not DirAccess.dir_exists_absolute(test_folder_path):
			DirAccess.make_dir_absolute(test_folder_path)
	
	_bus = EventBus.new()
	_bus.set_up()
	_library = Library.new()
	_library.set_bus(_bus)
	_save_system = SaveSystem.new()
	_save_system.set_dependacies(_bus, _library)
	_save_system.set_playlist_save_folder(test_save_dir)
	
	_bus.data.save_playlist.connect(_save_system.save_playlist)
	_bus.data.delete_playlist.connect(_save_system.delete_playlist_file)
	_bus.data.delete_playlist.connect(_library.remove_playlist)
	# Id managers id tracker is meant to be private and shouldn’t cause issues for any test if not
	# cleared
	

	gut.p("ran setup", 2)

var _bus: EventBus

var _library: Library

var _save_system: SaveSystem

func test_playlist_creation() -> void:
	var test_name: String = "PlaylistTest"
	var test_description: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do 
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
	quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

	# Simulate the popup
	var popup: PlaylistOptionsPopup = PLAYLIST_POPUP_SCENE.instantiate()
	popup.set_up(AppTool.PlaylistEditType.CREATE, _bus, _library)
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
	popup.set_up(AppTool.PlaylistEditType.EDIT, _bus, _library, playlist.id, cover_save_dir)
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
	popup.set_up(AppTool.PlaylistEditType.EDIT, _bus, _library, playlist.id)
	add_child(popup)

	# By passing the delete btn as that spawns a confirmation dialog
	_bus.data.delete_playlist.emit(playlist.id)

	assert_false(_library.playlist_exists(playlist_id), "Playlist was not deleted")
	assert_false(_library.playlist_with_name_exists(playlist_name), "Playlists name was not cleared from set")
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
	_save_system.set_playlist_save_folder(test_save_dir)


	# Make dummy playlist
	var playlist: Playlist = Playlist.new()
	playlist.storage_id = "99"
	playlist.id = AppState.id_manager.get_id_from_playlist_storage_id(playlist.storage_id)
	playlist.title = "Dummy"
	playlist.description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do 
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
	quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
	
	_library.add_playlist(playlist)
	_save_system.save_playlist(playlist)

	return playlist
