class_name AppearanceSection
extends Panel

@export_group("Theme")
@export var light_mode_btn: CheckBox
@export var dark_mode_btn: CheckBox


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
