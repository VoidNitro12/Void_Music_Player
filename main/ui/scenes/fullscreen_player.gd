class_name FullScreenPlayer
extends Control

@export var center_panels: Dictionary[AppTool.FullScreenCenterPanel,Panel]
@export var file_tab: FileTab


func _ready() -> void:
	file_tab.switch_center_panel.connect(switch_center_panel)
	file_tab.switch_main_tab_section.connect(center_panels[AppTool.FullScreenCenterPanel.MAIN].switch_section)

func switch_center_panel(to: AppTool.FullScreenCenterPanel) -> void: 
	for key: AppTool.FullScreenCenterPanel in center_panels.keys():
		if key == to:
			center_panels[key].visible = true
		else: 
			center_panels[key].visible = false
