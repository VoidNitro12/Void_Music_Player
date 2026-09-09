@tool
extends Node

const SHOW_DELAY_SECONDS := 0.6
const HIDE_DELAY_SECONDS := 0.2
const POPUP_OFFSET := Vector2(12, 18)

var _editor: CodeEdit
var _issues: Array[Dictionary] = []
var _show_timer: Timer
var _hide_timer: Timer
var _popup: PopupPanel
var _word_label: Label
var _pending_issue: Dictionary = {}
var _visible_issue: Dictionary = {}
var _last_mouse_screen_position := Vector2.ZERO


func setup(host: Control) -> void:
	_show_timer = Timer.new()
	_show_timer.one_shot = true
	_show_timer.wait_time = SHOW_DELAY_SECONDS
	_show_timer.timeout.connect(_show_pending_issue)
	add_child(_show_timer)

	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = HIDE_DELAY_SECONDS
	_hide_timer.timeout.connect(hide_card)
	add_child(_hide_timer)

	_popup = PopupPanel.new()
	_popup.popup_hide.connect(_on_popup_hidden)
	_popup.add_theme_stylebox_override("panel", _create_popup_style(host))
	host.add_child(_popup)

	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 12)
	content.add_theme_constant_override("margin_top", 8)
	content.add_theme_constant_override("margin_right", 12)
	content.add_theme_constant_override("margin_bottom", 8)
	_popup.add_child(content)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	content.add_child(row)

	_word_label = Label.new()
	_word_label.add_theme_font_override("font", host.get_theme_font("bold", "EditorFonts"))
	row.add_child(_word_label)

	var message_label := Label.new()
	message_label.text = ": Unknown word."
	row.add_child(message_label)


func _exit_tree() -> void:
	detach()
	if _popup != null:
		_popup.queue_free()


func attach(editor: CodeEdit) -> void:
	detach()
	_editor = editor
	_editor.gui_input.connect(_on_editor_gui_input)
	_editor.mouse_exited.connect(_on_editor_mouse_exited)


func detach() -> void:
	if _editor != null:
		if _editor.gui_input.is_connected(_on_editor_gui_input):
			_editor.gui_input.disconnect(_on_editor_gui_input)
		if _editor.mouse_exited.is_connected(_on_editor_mouse_exited):
			_editor.mouse_exited.disconnect(_on_editor_mouse_exited)
	_editor = null
	_issues.clear()
	hide_card()


func set_issues(issues: Array) -> void:
	_issues.clear()
	for issue in issues:
		if issue is Dictionary and issue.get("line", -1) >= 0:
			_issues.append(issue.duplicate())
	if not _visible_issue.is_empty() and not _has_issue(_visible_issue.id):
		hide_card()


func hide_card() -> void:
	if _show_timer != null:
		_show_timer.stop()
	if _hide_timer != null:
		_hide_timer.stop()
	_pending_issue = {}
	_visible_issue = {}
	if _popup != null and _popup.visible:
		_popup.hide()


func _on_editor_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_last_mouse_screen_position = _editor.get_screen_position() + event.position
		_update_hovered_issue(event.position)
	elif event is InputEventMouseButton or event is InputEventKey:
		hide_card()


func _update_hovered_issue(local_position: Vector2) -> void:
	var issue := _issue_at_position(local_position)
	if issue.is_empty():
		_cancel_show()
		_schedule_hide()
		return

	_hide_timer.stop()
	if not _visible_issue.is_empty() and _visible_issue.id == issue.id:
		return
	if not _pending_issue.is_empty() and _pending_issue.id == issue.id:
		return

	_pending_issue = issue
	_show_timer.start()


func _issue_at_position(local_position: Vector2) -> Dictionary:
	if _editor == null:
		return {}
	var line_column: Vector2i = _editor.get_line_column_at_pos(local_position, false, false)
	var column := line_column.x
	var line := line_column.y
	if line < 0 or column < 0:
		return {}
	return _find_issue(line, column)


func _find_issue(line: int, column: int) -> Dictionary:
	for issue in _issues:
		if issue.line == line and column >= issue.column and column < issue.column + issue.length:
			return issue
	return {}


func _show_pending_issue() -> void:
	if _pending_issue.is_empty() or _editor == null:
		return
	_visible_issue = _pending_issue
	_pending_issue = {}
	_word_label.text = "\"%s\"" % _visible_issue.word
	_popup.position = Vector2i(_last_mouse_screen_position + POPUP_OFFSET)
	_popup.reset_size()
	_popup.popup()


func _on_editor_mouse_exited() -> void:
	_cancel_show()
	_schedule_hide()


func _on_popup_hidden() -> void:
	_visible_issue = {}


func _cancel_show() -> void:
	_pending_issue = {}
	if _show_timer != null:
		_show_timer.stop()


func _cancel_hide() -> void:
	if _hide_timer != null:
		_hide_timer.stop()


func _schedule_hide() -> void:
	if _popup != null and _popup.visible:
		_hide_timer.start()


func _has_issue(issue_id: String) -> bool:
	for issue in _issues:
		if issue.id == issue_id:
			return true
	return false


func _create_popup_style(host: Control) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var background := host.get_theme_color("base_color", "Editor")
	var border := host.get_theme_color("contrast_color_1", "Editor")
	if background == Color():
		background = Color(0.12, 0.12, 0.12, 0.98)
	if border == Color():
		border = Color(1.0, 1.0, 1.0, 0.18)
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 5
	return style
