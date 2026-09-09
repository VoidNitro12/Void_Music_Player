class_name SettingsTab
extends Panel
## UI Root for all App settings

@export var toggles: Array[Button]

@export var section_panels: Array[Panel]

@export var toggle_match: Dictionary[Button, Panel]


func _ready() -> void:
	for button: Button in toggles:
		button.pressed.connect(toggle_section.bind(button))
	toggle_section(toggles[0])


func toggle_section(btn: Button) -> void:
	for button: Button in toggles:
		if button != btn:
			button.button_pressed = false
			if toggle_match.has(button):
				toggle_match[button].visible = false
		else:
			if toggle_match.has(button):
				toggle_match[button].visible = true
