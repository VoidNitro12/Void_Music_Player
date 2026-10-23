@tool
class_name IconBtn
extends Control
## Custom Btn for special handling of icons
# Spent way longer than id like to admit getting this to visually work
# while i technically could export text and icon allignments like normal buttons
# im just not gonna

signal pressed

signal toggled(value: bool)

@export var text: String = "":
	set(value):
		if text != value:
			text = value
			_text_label.text = value
			if text.is_empty():
				_text_label.visible = false
			else:
				_text_label.visible = true
			self.update_minimum_size()

@export var icon: Texture2D:
	set(value):
		if icon != value:
			icon = value
			_icon_rect.texture = value

@export var toggle_mode: bool = false:
	set(value):
		if toggle_mode != value:
			toggle_mode = value
			_btn.toggle_mode = value

@export var button_pressed: bool = false:
	set(value):
		if button_pressed != value:
			button_pressed = value
			_btn.button_pressed = value

@export var button_group: ButtonGroup:
	set(value):
		if button_group != value:
			button_group = value
			_btn.button_group = value

@export_group("SceneNodes", "_")
@export var _icon_rect: TextureRect
@export var _btn: Button
@export var _text_label: Label
@export var _btn_margin: MarginContainer


func _ready() -> void:
	
	_icon_rect.self_modulate = AppState.theme_manager.get_current_base_shade()
	
	# this currently spams errors due to being a tool script
	Events.ui.change_app_accent_colour.connect(
		func(to: ThemeManager.Accents) -> void:
			_icon_rect.self_modulate = ThemeManager.ACCENT_COLOURS[to],
	)

	_btn.pressed.connect(
		func() -> void:
			self.pressed.emit(),
	)

	_btn.toggled.connect(
		func(value: bool) -> void:
			self.toggled.emit(value),
	)

	self.toggled.connect(_handle_theme_labels)

	_btn.mouse_entered.connect(_icon_hover.bind(true))

	_btn.mouse_exited.connect(_icon_hover.bind(false))


func _get_minimum_size() -> Vector2:
	return _btn_margin.get_combined_minimum_size()

# so you can actually see the icons during a hover_pressed since chances are the hover shade
# will just swallow the base shade
func _icon_hover(entered: bool) -> void:
	if not (toggle_mode and _btn.button_pressed):
		return

	if entered:
		_icon_rect.self_modulate = AppState.theme_manager.get_current_selected_shade()
	else:
		_icon_rect.self_modulate = AppState.theme_manager.get_current_base_shade()


func _resize() -> void:
	self.size = _btn_margin.get_combined_minimum_size()


func _handle_theme_labels(selected: bool) -> void:
	if selected:
		_text_label.add_theme_color_override(
			"font_color",
			_btn.get_theme_color("font_pressed_color", "Button"),
		)
	else:
		_text_label.remove_theme_color_override("font_color")
