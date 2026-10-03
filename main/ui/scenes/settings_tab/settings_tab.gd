class_name SettingsTab
extends Panel
## UI Root for all App settings

@export var sections: TabContainer
@export var toggle_match: Dictionary[Button, int]


func _ready() -> void:
	for button: Button in toggle_match.keys():
		button.pressed.connect(toggle_section.bind(button))
	


func toggle_section(btn: Button) -> void:
	sections.current_tab = toggle_match[btn]
	
	for btns: Button in toggle_match.keys(): 
		btns.button_pressed = (btns == btn)
