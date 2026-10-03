@tool
extends EditorPlugin

const WordSplitterScript := preload("res://addons/gd_spell_guard/core/word_splitter.gd")
const SpellDictionaryScript := preload("res://addons/gd_spell_guard/core/spell_dictionary.gd")
const GDScriptScannerScript := preload("res://addons/gd_spell_guard/core/gdscript_scanner.gd")
const FileFilterScript := preload("res://addons/gd_spell_guard/core/file_filter.gd")
const IssuesPanelScript := preload("res://addons/gd_spell_guard/ui/issues_panel.gd")
const BottomPanelButtonScript := preload("res://addons/gd_spell_guard/ui/bottom_panel_button.gd")
const ManageWordsDialogScript := preload("res://addons/gd_spell_guard/ui/manage_words_dialog.gd")
const QuickFixHoverScript := preload("res://addons/gd_spell_guard/ui/quick_fix_hover.gd")

const TOOL_MENU_NAME := "Scan Spelling with GDSpellGuard"
const ALWAYS_EXCLUDED_PATHS := [
	"res://addons",
]
const DEFAULT_EXCLUDED_PATHS := [
	"res://.godot",
	"res://addons",
	"res://gd_spell_guard",
	"res://gd_spell_guard_dicts",
]
const FILES_PER_FRAME := 3
const QUICK_FIX_MENU_ID := 49021
const POPUP_IGNORE_ID := 10001
const SETTINGS := {
	"gd_spell_guard/check_comments": true,
	"gd_spell_guard/check_strings": true,
	"gd_spell_guard/check_identifiers": true,
	"gd_spell_guard/check_filenames": true,
	"gd_spell_guard/check_folder_names": true,
	"gd_spell_guard/check_scene_node_names": true,
	"gd_spell_guard/ignore_short_words": true,
	"gd_spell_guard/excluded_paths": DEFAULT_EXCLUDED_PATHS,
	"gd_spell_guard/active_dictionary": "en_GB",
	"gd_spell_guard/suggestion_limit": 8,
}

var _splitter
var _dictionary
var _scanner
var _panel
var _bottom_panel_button: Button
var _bottom_panel_issue_count := 0
var _bottom_panel_title := ""
var _bottom_panel_registered := false
var _script_editor: ScriptEditor
var _current_code_edit: CodeEdit
var _current_script: Script
var _current_path := ""
var _text_change_timer: Timer
var _filesystem_change_timer: Timer
var _issues_by_path: Dictionary = {}
var _scan_queue: Array[String] = []
var _folder_paths_in_scan: Dictionary = {}
var _project_scan_active := false
var _loaded_locale := ""
var _quick_fix_popup: PopupMenu
var _quick_fix_issue: Dictionary = {}
var _quick_fix_suggestions: Dictionary = {}
var _quick_fix_hover
var _code_menu: PopupMenu
var _manage_words_dialog


func _enter_tree() -> void:
	_register_project_settings()
	_splitter = WordSplitterScript.new()
	_dictionary = SpellDictionaryScript.new(_splitter)
	_load_dictionary()
	_scanner = GDScriptScannerScript.new(_dictionary, _splitter)
	_apply_scanner_settings()

	_panel = IssuesPanelScript.new()
	_register_bottom_panel(BottomPanelButtonScript.TITLE)
	_update_bottom_panel_button(0)
	_panel.issue_activated.connect(_on_issue_activated)
	_panel.manage_words_requested.connect(_show_manage_words)
	_panel.scan_requested.connect(scan_project)
	_panel.set_dictionary_status(_dictionary.active_locale, _dictionary.load_warning)

	add_tool_menu_item(TOOL_MENU_NAME, scan_project)
	_quick_fix_popup = PopupMenu.new()
	_quick_fix_popup.id_pressed.connect(_on_quick_fix_popup_id_pressed)
	get_editor_interface().get_base_control().add_child(_quick_fix_popup)
	_quick_fix_hover = QuickFixHoverScript.new()
	add_child(_quick_fix_hover)
	_quick_fix_hover.setup(get_editor_interface().get_base_control())
	_manage_words_dialog = ManageWordsDialogScript.new()
	_manage_words_dialog.remove_ignored_word_requested.connect(_on_remove_ignored_word_requested)
	_manage_words_dialog.add_ignored_word_requested.connect(_on_ignore_in_project_requested)
	_manage_words_dialog.settings_apply_requested.connect(_on_settings_apply_requested)
	get_editor_interface().get_base_control().add_child(_manage_words_dialog)

	_text_change_timer = Timer.new()
	_text_change_timer.one_shot = true
	_text_change_timer.wait_time = 0.5
	_text_change_timer.timeout.connect(_scan_current_editor)
	add_child(_text_change_timer)

	_filesystem_change_timer = Timer.new()
	_filesystem_change_timer.one_shot = true
	_filesystem_change_timer.wait_time = 1.0
	_filesystem_change_timer.timeout.connect(scan_project)
	add_child(_filesystem_change_timer)

	_script_editor = get_editor_interface().get_script_editor()
	_script_editor.editor_script_changed.connect(_on_editor_script_changed)
	resource_saved.connect(_on_resource_saved)
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	editor_filesystem.filesystem_changed.connect(_on_filesystem_changed)

	set_process(true)
	call_deferred("_attach_current_editor")
	call_deferred("scan_project")


func _exit_tree() -> void:
	set_process(false)
	_detach_current_editor()
	if _script_editor != null and _script_editor.editor_script_changed.is_connected(_on_editor_script_changed):
		_script_editor.editor_script_changed.disconnect(_on_editor_script_changed)
	if resource_saved.is_connected(_on_resource_saved):
		resource_saved.disconnect(_on_resource_saved)
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	if editor_filesystem != null and editor_filesystem.filesystem_changed.is_connected(_on_filesystem_changed):
		editor_filesystem.filesystem_changed.disconnect(_on_filesystem_changed)
	remove_tool_menu_item(TOOL_MENU_NAME)
	if _panel != null:
		if _bottom_panel_registered:
			remove_control_from_bottom_panel(_panel)
			_bottom_panel_registered = false
		_panel.queue_free()
	_bottom_panel_button = null
	_bottom_panel_title = ""
	if _quick_fix_popup != null:
		_quick_fix_popup.queue_free()
	if _manage_words_dialog != null:
		_manage_words_dialog.queue_free()


func _process(_delta: float) -> void:
	if not _project_scan_active:
		return
	var files_processed := 0
	while not _scan_queue.is_empty() and files_processed < FILES_PER_FRAME:
		var path := _scan_queue.pop_front()
		if _folder_paths_in_scan.has(path):
			_scan_folder(path)
		else:
			_scan_file(path)
		files_processed += 1
	_panel.set_scan_status(true, _scan_queue.size())
	if _scan_queue.is_empty():
		_project_scan_active = false
		_scan_current_editor()
		_refresh_results()


func scan_project() -> void:
	_ensure_dictionary_settings()
	_apply_scanner_settings()
	_quick_fix_hover.set_issues([])
	_scan_queue.clear()
	_folder_paths_in_scan.clear()
	_collect_files("res://", _scan_queue)
	_issues_by_path.clear()
	_project_scan_active = true
	_panel.set_scan_status(true, _scan_queue.size())


func _collect_files(directory_path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not _is_excluded(path) and not FileFilterScript.is_generated_or_hidden(path):
				_folder_paths_in_scan[path] = true
				output.append(path)
				_collect_files(path, output)
		else:
			if _should_check_file(path):
				output.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


func _scan_file(path: String) -> void:
	if not _should_check_file(path):
		_set_path_issues(path, [])
		return
	var issues: Array[Dictionary] = _scanner.scan_filename(path)
	var extension := path.get_extension().to_lower()
	if extension == "gd":
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			issues.append_array(_scanner.scan_text(file.get_as_text(), path))
	elif extension == "tscn":
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			issues.append_array(_scanner.scan_scene_text(file.get_as_text(), path))
	_set_path_issues(path, issues)


func _scan_folder(path: String) -> void:
	if _is_excluded(path) or FileFilterScript.is_generated_or_hidden(path):
		_set_path_issues(path, [])
		return
	_set_path_issues(path, _scanner.scan_folder_name(path))


func _scan_current_editor() -> void:
	if _current_code_edit == null or _current_script == null:
		return
	_apply_scanner_settings()
	_ensure_dictionary_settings()
	var path := _current_script.resource_path
	if path.is_empty():
		return
	if not _should_check_file(path):
		_set_path_issues(path, [])
		_refresh_results()
		return
	var issues: Array[Dictionary] = _scanner.scan_filename(path)
	issues.append_array(_scanner.scan_text(_current_code_edit.text, path))
	_set_path_issues(path, issues)
	_refresh_results()


func _set_path_issues(path: String, issues: Array[Dictionary]) -> void:
	if issues.is_empty():
		_issues_by_path.erase(path)
	else:
		_issues_by_path[path] = issues
	if _quick_fix_hover != null and path == _current_path:
		_quick_fix_hover.set_issues(issues)


func _refresh_results() -> void:
	var all_issues: Array[Dictionary] = []
	for path in _issues_by_path:
		for issue in _issues_by_path[path]:
			all_issues.append(issue)
	all_issues.sort_custom(_sort_issues)
	_panel.set_issues(all_issues)
	_update_bottom_panel_button(all_issues.size())


func _update_bottom_panel_button(issue_count: int) -> void:
	_bottom_panel_issue_count = issue_count
	var title := BottomPanelButtonScript.title_for_issue_count(issue_count)
	if title != _bottom_panel_title:
		_register_bottom_panel(title)
	_apply_bottom_panel_button_state()
	call_deferred("_apply_bottom_panel_button_state")


func _register_bottom_panel(title: String) -> void:
	if _panel == null:
		return
	var was_open: bool = _panel.is_visible_in_tree()
	if _bottom_panel_registered:
		remove_control_from_bottom_panel(_panel)
		_bottom_panel_registered = false
	_bottom_panel_button = add_control_to_bottom_panel(_panel, title)
	_bottom_panel_title = title
	_bottom_panel_registered = true
	if was_open:
		make_bottom_panel_item_visible(_panel)


func _apply_bottom_panel_button_state() -> void:
	if not is_inside_tree():
		return
	var updated := false
	if is_instance_valid(_bottom_panel_button):
		BottomPanelButtonScript.apply_issue_count(_bottom_panel_button, _bottom_panel_issue_count)
		updated = true
	var base_control := get_editor_interface().get_base_control()
	for button in BottomPanelButtonScript.find_gd_spell_guard_buttons(base_control):
		BottomPanelButtonScript.apply_issue_count(button, _bottom_panel_issue_count)
		_bottom_panel_button = button
		updated = true
	if not updated:
		_bottom_panel_button = null


func _sort_issues(left: Dictionary, right: Dictionary) -> bool:
	if left.path != right.path:
		return left.path < right.path
	if left.line != right.line:
		return left.line < right.line
	return left.column < right.column


func _on_editor_script_changed(script: Script) -> void:
	_current_script = script
	call_deferred("_attach_current_editor")


func _attach_current_editor() -> void:
	_detach_current_editor()
	_current_script = _script_editor.get_current_script()
	var script_editor_base := _script_editor.get_current_editor()
	if script_editor_base == null:
		return
	var base_editor := script_editor_base.get_base_editor()
	if not base_editor is CodeEdit:
		return
	_current_code_edit = base_editor
	_current_path = _current_script.resource_path if _current_script != null else ""
	_current_code_edit.text_changed.connect(_on_current_text_changed)
	_current_code_edit.gui_input.connect(_on_code_gui_input)
	_quick_fix_hover.attach(_current_code_edit)
	var current_issues: Array[Dictionary] = []
	if _issues_by_path.has(_current_path):
		current_issues.append_array(_issues_by_path[_current_path])
	_quick_fix_hover.set_issues(current_issues)
	_code_menu = _current_code_edit.get_menu()
	_code_menu.add_separator()
	_code_menu.add_item("GDSpellGuard Quick Fix", QUICK_FIX_MENU_ID)
	_code_menu.id_pressed.connect(_on_code_menu_id_pressed)
	_scan_current_editor()


func _detach_current_editor() -> void:
	if _current_code_edit == null:
		return
	if _current_code_edit.text_changed.is_connected(_on_current_text_changed):
		_current_code_edit.text_changed.disconnect(_on_current_text_changed)
	if _current_code_edit.gui_input.is_connected(_on_code_gui_input):
		_current_code_edit.gui_input.disconnect(_on_code_gui_input)
	_quick_fix_hover.detach()
	if _code_menu != null:
		if _code_menu.id_pressed.is_connected(_on_code_menu_id_pressed):
			_code_menu.id_pressed.disconnect(_on_code_menu_id_pressed)
		var item_index := _code_menu.get_item_index(QUICK_FIX_MENU_ID)
		if item_index >= 0:
			_code_menu.remove_item(item_index)
	_code_menu = null
	_current_code_edit = null
	_current_path = ""


func _on_current_text_changed() -> void:
	_quick_fix_hover.set_issues([])
	_text_change_timer.start()


func _on_issue_activated(issue: Dictionary) -> void:
	if issue.line < 0:
		get_editor_interface().get_file_system_dock().navigate_to_path(issue.path)
		return
	if issue.kind == "scene_node":
		get_editor_interface().get_file_system_dock().navigate_to_path(issue.path)
		return
	var script := load(issue.path) as Script
	if script != null:
		get_editor_interface().edit_script(script, issue.line, issue.column, true)


func _on_code_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_PERIOD:
		if event.meta_pressed or event.ctrl_pressed:
			_show_quick_fix()
			_current_code_edit.accept_event()


func _on_code_menu_id_pressed(id: int) -> void:
	if id == QUICK_FIX_MENU_ID:
		_show_quick_fix()


func _show_quick_fix(issue: Dictionary = {}) -> void:
	_quick_fix_hover.hide_card()
	_quick_fix_issue = issue if not issue.is_empty() else _issue_under_caret()
	_quick_fix_suggestions.clear()
	_quick_fix_popup.clear()
	_quick_fix_popup.add_separator("Quick Fix")
	if _quick_fix_issue.is_empty():
		_quick_fix_popup.add_item("No spelling fixes available here")
		_quick_fix_popup.set_item_disabled(_quick_fix_popup.item_count - 1, true)
	else:
		var limit: int = ProjectSettings.get_setting("gd_spell_guard/suggestion_limit", 8)
		var suggestions: Array[String] = _dictionary.suggest(_quick_fix_issue.word, limit)
		for index in range(suggestions.size()):
			_quick_fix_suggestions[index] = suggestions[index]
			_quick_fix_popup.add_item(suggestions[index], index)
		if suggestions.is_empty():
			_quick_fix_popup.add_item("No suggestions")
			_quick_fix_popup.set_item_disabled(_quick_fix_popup.item_count - 1, true)
		_quick_fix_popup.add_separator()
		_quick_fix_popup.add_item("Ignore \"%s\" in This Project" % _quick_fix_issue.word, POPUP_IGNORE_ID)
	var popup_position := Vector2i(_current_code_edit.get_screen_position() + _current_code_edit.get_caret_draw_pos())
	_quick_fix_popup.position = popup_position
	_quick_fix_popup.popup()


func _issue_under_caret() -> Dictionary:
	if _current_code_edit == null or not _issues_by_path.has(_current_path):
		return {}
	var line := _current_code_edit.get_caret_line()
	var column := _current_code_edit.get_caret_column()
	return _issue_at_position(line, column)


func _issue_at_position(line: int, column: int) -> Dictionary:
	if not _issues_by_path.has(_current_path):
		return {}
	for issue in _issues_by_path[_current_path]:
		if issue.line == line and column >= issue.column and column < issue.column + issue.length:
			return issue
	return {}


func _on_quick_fix_popup_id_pressed(id: int) -> void:
	if _quick_fix_issue.is_empty():
		return
	if _quick_fix_suggestions.has(id):
		_apply_suggestion(_quick_fix_issue, _quick_fix_suggestions[id])
	elif id == POPUP_IGNORE_ID:
		_on_ignore_in_project_requested(_quick_fix_issue.word)


func _apply_suggestion(issue: Dictionary, suggestion: String) -> void:
	if issue.line < 0:
		return
	if _current_path != issue.path:
		_on_issue_activated(issue)
		await get_tree().process_frame
		await get_tree().process_frame
	if _current_code_edit == null or _current_path != issue.path or issue.line >= _current_code_edit.get_line_count():
		return
	var line_text := _current_code_edit.get_line(issue.line)
	if line_text.substr(issue.column, issue.length) != issue.word:
		_scan_current_editor()
		return
	_current_code_edit.begin_complex_operation()
	_current_code_edit.select(issue.line, issue.column, issue.line, issue.column + issue.length)
	_current_code_edit.delete_selection()
	_current_code_edit.insert_text_at_caret(suggestion)
	_current_code_edit.end_complex_operation()
	_scan_current_editor()


func _on_ignore_in_project_requested(word: String) -> void:
	var error: Error = _dictionary.add_ignored_word(word)
	if error != OK:
		push_error("GDSpellGuard could not write res://gd_spell_guard/ignored_words.txt (error %d)." % error)
		return
	_remove_word_issues(word)
	_refresh_manage_words_dialog()


func _show_manage_words() -> void:
	_refresh_manage_words_dialog()
	_manage_words_dialog.popup_centered()


func _refresh_manage_words_dialog() -> void:
	_manage_words_dialog.set_state(
		_dictionary.get_ignored_words(),
		_dictionary.active_locale,
		ProjectSettings.get_setting("gd_spell_guard/ignore_short_words", true)
	)


func _on_remove_ignored_word_requested(word: String) -> void:
	var error: Error = _dictionary.remove_ignored_word(word)
	if error != OK:
		push_error("GDSpellGuard could not update res://gd_spell_guard/ignored_words.txt (error %d)." % error)
		return
	_refresh_manage_words_dialog()
	scan_project()


func _on_settings_apply_requested(locale: String, ignore_short_words: bool) -> void:
	if locale not in ["en_GB", "en_US"]:
		return
	ProjectSettings.set_setting("gd_spell_guard/active_dictionary", locale)
	ProjectSettings.set_setting("gd_spell_guard/ignore_short_words", ignore_short_words)
	var save_error := ProjectSettings.save()
	if save_error != OK:
		push_error("GDSpellGuard could not save its settings (error %d)." % save_error)
	_load_dictionary()
	_apply_scanner_settings()
	_refresh_manage_words_dialog()
	scan_project()


func _remove_word_issues(word: String) -> void:
	var normalized: String = _dictionary.normalize(word)
	for path in _issues_by_path.keys():
		var filtered: Array[Dictionary] = []
		for issue in _issues_by_path[path]:
			if _dictionary.normalize(issue.word) != normalized:
				filtered.append(issue)
		_set_path_issues(path, filtered)
	_refresh_results()


func _on_resource_saved(resource: Resource) -> void:
	if resource != null and not resource.resource_path.is_empty() and _should_check_file(resource.resource_path):
		_scan_file(resource.resource_path)
		_refresh_results()


func _on_filesystem_changed() -> void:
	_loaded_locale = ""
	_filesystem_change_timer.start()


func _is_excluded(path: String) -> bool:
	var generated_root: String = SpellDictionaryScript.IGNORED_WORDS_PATH.get_base_dir()
	var excluded_paths: Array = ProjectSettings.get_setting(
		"gd_spell_guard/excluded_paths",
		DEFAULT_EXCLUDED_PATHS
	)
	return FileFilterScript.is_excluded(path, ALWAYS_EXCLUDED_PATHS, excluded_paths, generated_root)


func _should_check_file(path: String) -> bool:
	var generated_root: String = SpellDictionaryScript.IGNORED_WORDS_PATH.get_base_dir()
	var excluded_paths: Array = ProjectSettings.get_setting(
		"gd_spell_guard/excluded_paths",
		DEFAULT_EXCLUDED_PATHS
	)
	return FileFilterScript.should_check_file(path, ALWAYS_EXCLUDED_PATHS, excluded_paths, generated_root)


func _register_project_settings() -> void:
	for setting_name in SETTINGS:
		var default_value: Variant = SETTINGS[setting_name]
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, default_value)
		ProjectSettings.set_initial_value(setting_name, default_value)
		var property_info := {
			"name": setting_name,
			"type": typeof(default_value),
		}
		if setting_name == "gd_spell_guard/active_dictionary":
			property_info["hint"] = PROPERTY_HINT_ENUM
			property_info["hint_string"] = "en_GB,en_US"
		ProjectSettings.add_property_info(property_info)


func _apply_scanner_settings() -> void:
	if _scanner == null:
		return
	_scanner.check_comments = ProjectSettings.get_setting("gd_spell_guard/check_comments", true)
	_scanner.check_strings = ProjectSettings.get_setting("gd_spell_guard/check_strings", true)
	_scanner.check_identifiers = ProjectSettings.get_setting("gd_spell_guard/check_identifiers", true)
	_scanner.check_filenames = ProjectSettings.get_setting("gd_spell_guard/check_filenames", true)
	_scanner.check_folder_names = ProjectSettings.get_setting("gd_spell_guard/check_folder_names", true)
	_scanner.check_scene_node_names = ProjectSettings.get_setting("gd_spell_guard/check_scene_node_names", true)
	_scanner.ignore_short_words = ProjectSettings.get_setting("gd_spell_guard/ignore_short_words", true)


func _load_dictionary() -> void:
	var locale: String = ProjectSettings.get_setting("gd_spell_guard/active_dictionary", "en_GB")
	var error: Error = _dictionary.load_all(locale, "")
	_loaded_locale = locale
	if error != OK or not _dictionary.load_warning.is_empty():
		push_error("GDSpellGuard dictionary: " + _dictionary.load_warning)
	if _panel != null:
		_panel.set_dictionary_status(_dictionary.active_locale, _dictionary.load_warning)


func _ensure_dictionary_settings() -> void:
	var locale: String = ProjectSettings.get_setting("gd_spell_guard/active_dictionary", "en_GB")
	if locale != _loaded_locale:
		_load_dictionary()
