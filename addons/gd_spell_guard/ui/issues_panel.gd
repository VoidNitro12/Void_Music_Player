@tool
extends VBoxContainer

signal issue_activated(issue: Dictionary)
signal manage_words_requested
signal scan_requested

var _tree: Tree
var _status_label: Label
var _quick_fix_help: HBoxContainer
var _expanded_files: Dictionary = {}
var _error_color := Color(1.0, 0.35, 0.35)


func _ready() -> void:
	name = "GDSpellGuard"
	custom_minimum_size = Vector2(0, 210)
	_error_color = get_theme_color("error_color", "Editor")
	if _error_color == Color():
		_error_color = get_theme_color("error_color", "EditorSettings")
	if _error_color == Color():
		_error_color = Color(1.0, 0.35, 0.35)

	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	var scan_button := Button.new()
	scan_button.text = "Scan Spelling"
	scan_button.pressed.connect(func(): scan_requested.emit())
	toolbar.add_child(scan_button)
	var manage_button := Button.new()
	manage_button.text = "Settings"
	manage_button.pressed.connect(func(): manage_words_requested.emit())
	toolbar.add_child(manage_button)
	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toolbar.add_child(_status_label)

	_quick_fix_help = HBoxContainer.new()
	_quick_fix_help.add_theme_constant_override("separation", 6)
	add_child(_quick_fix_help)
	var help_label := Label.new()
	help_label.text = "To view suggestions, place the text cursor inside a reported code word, then press"
	help_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_quick_fix_help.add_child(help_label)
	_quick_fix_help.add_child(_create_shortcut_badge("Command + ."))
	var or_label := Label.new()
	or_label.text = "or"
	_quick_fix_help.add_child(or_label)
	_quick_fix_help.add_child(_create_shortcut_badge("Ctrl + ."))

	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 1
	_tree.hide_root = true
	_tree.item_mouse_selected.connect(_on_item_mouse_selected)
	_tree.item_activated.connect(_on_item_activated)
	_tree.item_collapsed.connect(_on_item_collapsed)
	add_child(_tree)
	set_issues([])


func set_issues(issues: Array[Dictionary]) -> void:
	if _tree == null:
		return
	_tree.clear()
	var root := _tree.create_item()
	var files: Dictionary = {}
	for issue in issues:
		if not files.has(issue.path):
			files[issue.path] = []
		files[issue.path].append(issue)
	var paths: Array = files.keys()
	paths.sort()
	for path in paths:
		var file_item := _tree.create_item(root)
		var count: int = files[path].size()
		file_item.set_text(0, "%s  %d %s" % [path, count, "issue" if count == 1 else "issues"])
		file_item.set_custom_color(0, _error_color)
		file_item.set_metadata(0, {"type": "file", "path": path})
		file_item.collapsed = not _expanded_files.has(path)
		for issue in files[path]:
			var issue_item := _tree.create_item(file_item)
			issue_item.set_text(0, _issue_label(issue))
			issue_item.set_metadata(0, {"type": "issue", "issue": issue})
	_status_label.text = "%d issue%s" % [issues.size(), "" if issues.size() == 1 else "s"]


func set_scan_status(scanning: bool, remaining: int = 0) -> void:
	if _status_label != null and scanning:
		_status_label.text = "Scanning... %d items remaining" % remaining


func set_dictionary_status(locale: String, warning: String) -> void:
	if _status_label == null:
		return
	_status_label.tooltip_text = warning
	if not warning.is_empty():
		_status_label.text = "%s (fallback)" % locale


func _issue_label(issue: Dictionary) -> String:
	if issue.kind == "folder":
		return "\"%s\": Unknown word. [Folder name issue]" % issue.word
	if issue.kind == "scene_node":
		return "\"%s\": Unknown word. [Scene node name issue. Ln %d, Col %d]" % [
			issue.word,
			issue.line + 1,
			issue.column + 1,
		]
	if issue.line < 0:
		return "\"%s\": Unknown word. [Filename issue]" % issue.word
	return "\"%s\": Unknown word. [Ln %d, Col %d]" % [issue.word, issue.line + 1, issue.column + 1]


func _create_shortcut_badge(text: String) -> Label:
	var badge := Label.new()
	badge.text = text
	badge.add_theme_constant_override("outline_size", 0)
	var style := StyleBoxFlat.new()
	var background := get_theme_color("dark_color_2", "Editor")
	var border := get_theme_color("contrast_color_1", "Editor")
	if background == Color():
		background = Color(0.18, 0.18, 0.18, 1.0)
	if border == Color():
		border = Color(1.0, 1.0, 1.0, 0.18)
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("normal", style)
	return badge


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	var item := _tree.get_selected()
	if item == null:
		return
	var metadata: Dictionary = item.get_metadata(0)
	if metadata.get("type", "") == "file":
		item.collapsed = not item.collapsed
		_on_item_collapsed(item)


func _on_item_activated() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	var metadata: Dictionary = item.get_metadata(0)
	if metadata.get("type", "") == "issue":
		issue_activated.emit(metadata.issue)


func _on_item_collapsed(item: TreeItem) -> void:
	var metadata: Dictionary = item.get_metadata(0)
	if metadata.get("type", "") != "file":
		return
	if item.collapsed:
		_expanded_files.erase(metadata.path)
	else:
		_expanded_files[metadata.path] = true


func _find_issue_item(issue_id: String) -> TreeItem:
	var item := _tree.get_root().get_next_in_tree()
	while item != null:
		var metadata = item.get_metadata(0)
		if metadata is Dictionary and metadata.get("type") == "issue" and metadata.issue.id == issue_id:
			return item
		item = item.get_next_in_tree()
	return null


func _find_file_item(path: String) -> TreeItem:
	var item := _tree.get_root().get_next_in_tree()
	while item != null:
		var metadata = item.get_metadata(0)
		if metadata is Dictionary and metadata.get("type") == "file" and metadata.path == path:
			return item
		item = item.get_next_in_tree()
	return null
