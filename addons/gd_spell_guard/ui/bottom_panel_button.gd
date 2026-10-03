@tool
extends RefCounted

const TITLE := "GDSpellGuard"
const BUTTON_NAME := "gd_spell_guard_bottom_panel_button"


static func apply_issue_count(button: Button, issue_count: int) -> void:
	if button == null:
		return
	button.name = BUTTON_NAME
	if issue_count <= 0:
		button.set_text(title_for_issue_count(issue_count))
		button.tooltip_text = ""
		button.queue_redraw()
		return

	button.set_text(title_for_issue_count(issue_count))
	button.tooltip_text = "%d spelling %s" % [issue_count, "issue" if issue_count == 1 else "issues"]
	button.queue_redraw()


static func title_for_issue_count(issue_count: int) -> String:
	if issue_count <= 0:
		return TITLE
	return "%s (%d)" % [TITLE, issue_count]


static func find_gd_spell_guard_buttons(root: Node) -> Array[Button]:
	var matches: Array[Button] = []
	_collect_gd_spell_guard_buttons(root, matches)
	return matches


static func _collect_gd_spell_guard_buttons(node: Node, matches: Array[Button]) -> void:
	if node == null:
		return
	if node is Button and _is_gd_spell_guard_button(node):
		matches.append(node)
	for child in node.get_children():
		_collect_gd_spell_guard_buttons(child, matches)


static func _is_gd_spell_guard_button(button: Button) -> bool:
	return (
		button.name == BUTTON_NAME
		or button.text == TITLE
		or button.text.begins_with(TITLE + " (")
	)
