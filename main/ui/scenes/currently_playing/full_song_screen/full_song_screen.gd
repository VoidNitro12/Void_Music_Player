class_name FullSongScreen
extends BaseCurrentPlayingBar

@export_group("Top Controls")
@export var hide_btn: IconBtn

@export_group("Song Panel")

@export_subgroup("Seeker")
@export var time_played_label: Label
@export var duration_label: Label

var _pop_tween: Tween
var animation_duration: float = 0.7

# Private holder of what this screen will be based of
var _current_playing: RequestObj

func _ready() -> void:
	# size which this depends on would likely not be ready in configure
	pop_out()

func _configure() -> void:
	super()
	hide_btn.set_bus(_bus)
	
	hide_btn.pressed.connect(func()->void: _bus.ui.show_full_song_screen.emit(false))
	
	

## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	if data == null:
		return
	if data.entry_data == null:
		return
	super(data)
	_current_playing = data
	duration_label.text = AppTool.duration_to_timestamp(data.entry_data.raw_length)

func pop_in() -> void:
	_kill_tween_if_valid()
	_set_tween()
	self.visible = true
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), animation_duration)

func pop_out() -> void:
	_kill_tween_if_valid()
	_set_tween()
	var off_point_y: float = abs(self.size.y + (self.size.y / 3)) # Its size and a bit more
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, off_point_y), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(0.2, 1.0), animation_duration)
	await _pop_tween.finished
	self.visible = false

func _kill_tween_if_valid() -> void :
	if _pop_tween and _pop_tween.is_valid():
		_pop_tween.kill()

func _set_tween() -> void:
	_pop_tween = create_tween()
	_pop_tween.set_parallel(true)
	_pop_tween.set_trans(Tween.TRANS_EXPO)
	_pop_tween.set_ease(Tween.EASE_IN_OUT)

func _update_current_play_info(raw_length: float) -> void:
	super(raw_length)
	time_played_label.text = AppTool.duration_to_timestamp(raw_length)
