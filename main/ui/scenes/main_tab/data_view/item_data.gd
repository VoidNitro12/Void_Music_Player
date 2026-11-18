class_name ItemData
extends RefCounted
## Small class for bundling info to be passed int a [VirtualScroll] class for setting its
## [ContainerEntry] based data nodes

## If the items are selection items 
var is_selection: bool = false

## If the items are to be interactable or not
var display_only: bool = false

var btn_group: ButtonGroup = null

func _init(selection: bool, show_only: bool, button_group: ButtonGroup) -> void:
	is_selection = selection
	display_only = show_only
	btn_group = button_group

