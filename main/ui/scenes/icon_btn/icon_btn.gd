@tool
class_name IconBtn
extends Control
## Custom Btn for special handling of icons

@export_group("SceneNodes", "_")
@export var _icon_rect: TextureRect
@export var _btn: Button

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
