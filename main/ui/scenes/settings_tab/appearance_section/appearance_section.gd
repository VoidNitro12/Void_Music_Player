class_name SettingsAppearanceSection
extends Panel

@export_group("Theme")
@export var light_mode_btn: CheckBox
@export var dark_mode_btn: CheckBox

@export_group("Accent")
@export var accent_btn_container: HBoxContainer
@export var lighten_ratio: OptionSlider
@export var darken_ratio: OptionSlider
var accent_colour_btns: Dictionary[ThemeManager.Accents, Button]


func _ready() -> void:
	var theme_btn_group: ButtonGroup = ButtonGroup.new()
	light_mode_btn.button_group = theme_btn_group
	dark_mode_btn.button_group = theme_btn_group
	
	light_mode_btn.toggled.connect(func(on: bool)->void:
		if on:
			AppEvents.ui.change_app_theme.emit(AppTool.AppThemes.LIGHT)
		)
	
	dark_mode_btn.toggled.connect(func(on: bool)->void:
		if on:
			AppEvents.ui.change_app_theme.emit(AppTool.AppThemes.DARK)
		)
	
	dark_mode_btn.set_pressed_no_signal(true)
	
	_setup_accent_options()
	
	AppEvents.ui.change_app_accent_colour.connect(func(to: ThemeManager.Accents)->void: 
		# so code changes still visibly select the btns
		accent_colour_btns[to].set_pressed_no_signal(true)
		)
	
	lighten_ratio.value_changed.connect(func(value: float)->void: 
		AppEvents.ui.change_accent_lighten_amount.emit(value))
	
	darken_ratio.value_changed.connect(func(value: float)->void: 
		AppEvents.ui.change_accent_darken_amount.emit(value))
	
	AppEvents.ui.set_accent_ratio_no_signal.connect(func(lighten: float, darken: float)->void: 
		lighten_ratio.set_value_no_signal(lighten)
		darken_ratio.set_value_no_signal(darken))
	

# Dont want to have to change the btns whenever i mess with accents
func _setup_accent_options() -> void:
	var btn_group: ButtonGroup = ButtonGroup.new()
	 
	for i: int in ThemeManager.Accents.values(): 
		var btn: Button = Button.new()
		btn.toggle_mode = true
		btn.button_group = btn_group
		
		btn.custom_minimum_size = Vector2(60.0, 60.0)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Theme overrides as they have to be their respective colours
		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.bg_color = ThemeManager.ACCENT_COLOURS[i]
		normal.set_corner_radius_all(30)
		
		var hover: StyleBoxFlat = StyleBoxFlat.new()
		hover.bg_color = ThemeManager.ACCENT_COLOURS[i]
		hover.set_border_width_all(2)
		hover.set_corner_radius_all(30)
		
		var pressed: StyleBoxFlat = StyleBoxFlat.new()
		pressed.bg_color = ThemeManager.ACCENT_COLOURS[i]
		pressed.set_border_width_all(3)
		pressed.border_color = Color(1.0, 1.0, 1.0, 1.0) #Generic white for now
		pressed.set_corner_radius_all(30)
		
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover_pressed", hover)
		
		btn.pressed.connect(func()-> void:
			AppEvents.ui.change_app_accent_colour.emit(i)
			)
		
		accent_btn_container.add_child(btn)
		accent_colour_btns[i] = btn
