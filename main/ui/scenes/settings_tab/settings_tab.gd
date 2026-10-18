class_name SettingsTab
extends Panel
## UI Root for all App settings

@export var sections: TabContainer
@export var toggle_match: Dictionary[IconBtn, int]


func _ready() -> void:
	var toggle_btn_group: ButtonGroup = ButtonGroup.new()
	for button: IconBtn in toggle_match.keys():
		button.pressed.connect(toggle_section.bind(button))
		button.button_group = toggle_btn_group
	
	# Default to the first section
	toggle_match.keys()[0].button_pressed = true
	toggle_section(toggle_match.keys()[0])
	
	# file scanning is the first tab and entry im toggle match
	AppEvents.redirect.to_file_scanning.connect(func()->void:
		toggle_match.keys()[0].button_pressed = true
	)

func toggle_section(btn: IconBtn) -> void:
	sections.current_tab = toggle_match[btn]
