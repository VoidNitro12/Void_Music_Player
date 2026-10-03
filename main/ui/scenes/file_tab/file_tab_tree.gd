class_name FileTabTree
extends Tree
## Custom class for unique Tree child highlighting and behaviour
## @experimental

var prev_item_highlight: TreeItem
var hover_process: bool = false
var hover_exempts: Array[TreeItem]

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exit)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if hover_process:
			_custom_highlight()

func _on_mouse_entered() -> void: 
	hover_process = true

func _on_mouse_exit() -> void: 
	hover_process = false
	_unhover_previous()

func _custom_highlight() -> void: 
	var item: TreeItem = get_item_at_position(get_local_mouse_position())
	if item != null and item not in hover_exempts:
		_unhover_previous()
		item.set_custom_bg_color(0,Color(0.804, 0.0, 0.0, 0.957))
		prev_item_highlight = item
	else:
		_unhover_previous()

func _unhover_previous() -> void: 
	if prev_item_highlight != null and is_instance_valid(prev_item_highlight):
		prev_item_highlight.set_custom_bg_color(0,Color(0.0, 0.0, 0.0, 0.0))
