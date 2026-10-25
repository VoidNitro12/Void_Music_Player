class_name SettingsTab
extends SceneBase
## UI Root for all App settings

@export var sections: TabContainer
@export var toggle_match: Dictionary[IconBtn, int]

@export var lib_section: SettingsLibrarySection
@export var appearance_section: SettingsAppearanceSection

func _configure() -> void: 
	var toggle_btn_group: ButtonGroup = ButtonGroup.new()
	for button: IconBtn in toggle_match.keys():
		button.pressed.connect(toggle_section.bind(button))
		button.button_group = toggle_btn_group
		button.set_bus(_bus)
	
	lib_section.set_bus(_bus)
	appearance_section.set_bus(_bus)
	
	# Default to the first section
	toggle_match.keys()[0].button_pressed = true
	toggle_section(toggle_match.keys()[0])
	
	# file scanning is the first tab and entry im toggle match
	_bus.redirect.to_file_scanning.connect(func()->void:
		toggle_match.keys()[0].button_pressed = true
	)

func toggle_section(btn: IconBtn) -> void:
	sections.current_tab = toggle_match[btn]
