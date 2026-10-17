@tool
class_name IconBtn
extends Control
## Custom Btn for special handling of icons

# Spent way longer than id like to admit getting this to visually work
# while i technically could export text and icon allignments like normal buttons 
# im just not gonna

@export_group("SceneNodes", "_")
@export var _icon_rect: TextureRect
@export var _btn: Button
@export var _text_label: Label
@export var _btn_margin: MarginContainer

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


signal pressed

signal toggled(value: bool)

func _ready() -> void:
	AppEvents.ui.change_app_accent_colour.connect(func(to: ThemeManager.Accents)->void: 
		_icon_rect.self_modulate = ThemeManager.ACCENT_COLOURS[to]
		)
	
	_btn.pressed.connect(func()->void: self.pressed.emit())
	
	_btn.toggled.connect(func(value: bool)-> void: self.toggled.emit(value))

func _get_minimum_size() -> Vector2:
	return _btn_margin.get_combined_minimum_size()

func _resize() -> void:
	self.size = _btn_margin.get_combined_minimum_size()
