@tool
class_name OptionSlider
extends Control
## Reusable scene for sliders that show off their percentage and label themselves

signal value_changed(value: bool)

@export var text: String:
	set(value):
		if value != text:
			_text_label.text = value
			text = value

@export var slider_min: float:
	set(value):
		if value != slider_min:
			_slider.min_value = value
			slider_min = value

@export var slider_max: float:
	set(value):
		if value != slider_max:
			_slider.max_value = value
			slider_max = value

@export var slider_step: float:
	set(value):
		if value != slider_step:
			_slider.step = value
			slider_step = value

@export_group("Scene_nodes", "_")
@export var _text_label: Label
@export var _slider: HSlider
@export var _value_label: Label
@export var _apply_timer: Timer

var _value_changed_wait_time: float = 0.2


func _ready() -> void:
	_slider.value_changed.connect(_on_value_changed)

	_apply_timer.timeout.connect(
		func() -> void:
			value_changed.emit(_slider.value),
	)


func _on_value_changed(value: float) -> void:
	_value_label.text = str(int((value / 1) * 100)) + "%"
	_apply_timer.start(_value_changed_wait_time)

func set_value_no_signal(value: float) -> void: 
	_slider.set_value_no_signal(value)
	_value_label.text = str(int((value / 1) * 100)) + "%"
