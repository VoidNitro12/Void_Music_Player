class_name LoadingPopup
extends Window
## Window that blocks input from the rest of the app while showing an animation
## to the user

@export var wait_text_label: Label

## Sets up the container with relevant data.[br]
## [param wait_text] is the text shown while the window is up, if this function is not called,
## shows "Please Wait"
func set_data(wait_text: String) -> void: 
	wait_text_label.text = wait_text
