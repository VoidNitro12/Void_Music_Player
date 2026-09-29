class_name MiniPlayer
extends BaseCurrentPlayingBar

@export_group("Controls")
@export var full_screen_btn: Button

func _ready() -> void:
	super()
	full_screen_btn.pressed.connect(
	func() -> void:
		AppEvents.ui.switch_to_mini_player.emit(false),
	)
