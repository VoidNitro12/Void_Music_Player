class_name MiniPlayer
extends BaseCurrentPlayingBar

@export_group("Controls")
@export var full_screen_btn: IconBtn

func _configure() -> void:
	super()
	full_screen_btn.pressed.connect(
	func() -> void:
		_bus.ui.switch_to_mini_player.emit(false),
	)
