class_name VolumeSliderPopup
extends SceneBase

@export var icon: TextureRect
@export var slider: HSlider
@export var percent_label: Label

var _pop_tween: Tween
var animation_duration: float = 0.7

func _configure() -> void:
	super()

	slider.value_changed.connect(_change_volume)
	
	_bus.audio.volume_changed.connect(_set_percentage_label)
	
	pop_out()
	

func _change_volume(value: float) -> void:
	_bus.audio.set_volume.emit(value)

func _set_percentage_label(value: float) -> void: 
	var percent: float = ((value/1) * 100)
	percent_label.text = "%.0f%%" % percent

func pop_in() -> void:
	_kill_tween_if_valid()
	_set_tween()
	self.visible = true
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), animation_duration)
	
	

func pop_out() -> void:
	_kill_tween_if_valid()
	_set_tween()
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, 80.0), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(0.2, 1.0), animation_duration)
	await _pop_tween.finished 
	self.visible = false

func _kill_tween_if_valid() -> void :
	if _pop_tween and _pop_tween.is_valid():
		_pop_tween.kill()

func _set_tween() -> void: 
	_pop_tween = create_tween()
	_pop_tween.set_parallel(true)
	_pop_tween.set_trans(Tween.TRANS_ELASTIC)
	_pop_tween.set_ease(Tween.EASE_OUT)