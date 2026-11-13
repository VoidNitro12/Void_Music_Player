class_name FullSongScreen
extends BaseCurrentPlayingBar

@export_group("Top Controls")
@export var hide_btn: IconBtn
@export var queue_btn: IconBtn
@export var volume_btn: IconBtn
@export var volume_slider_popup: VolumeSliderPopup

@export_group("Song Panel")
@export var song_panel: Panel
@export_subgroup("Seeker")
@export var time_played_label: Label
@export var duration_label: Label

@export_group("Extra Details Panel")
@export var extra_details_panel: Panel
@export var queue_tab: QueueTab

var _pop_tween: Tween
var _detail_tween: Tween
var animation_duration: float = 0.7

# Private holder of what this screen will be based of
var _current_playing: RequestObj

func _ready() -> void:
	# size which this depends on would likely not be ready in configure
	pop_out()
	

func _configure() -> void:
	super()
	hide_btn.set_bus(_bus)
	volume_slider_popup.set_bus(_bus)
	volume_btn.set_bus(_bus)
	queue_btn.set_bus(_bus)
	queue_tab.set_bus(_bus)
	
	hide_btn.pressed.connect(func()->void: _bus.ui.show_full_song_screen.emit(false))

	volume_btn.pressed.connect(toggle_slider_visibility)
	volume_slider_popup.pop_out_direction = VolumeSliderPopup.PopOutDirection.Y_UP
	volume_slider_popup.pop_out()
	
	queue_btn.toggled.connect(show_extra_details)
	
	

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
	_kill_tween_if_valid(_pop_tween)
	_pop_tween = _set_tween()
	self.visible = true
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), animation_duration)

func pop_out() -> void:
	_kill_tween_if_valid(_pop_tween)
	_pop_tween = _set_tween()
	var off_point_y: float = abs(self.size.y + (self.size.y / 3)) # Its size and a bit more
	_pop_tween.tween_property(self, "offset_transform_position", Vector2(0.0, off_point_y), animation_duration)
	_pop_tween.tween_property(self, "offset_transform_scale", Vector2(0.2, 1.0), animation_duration)
	await _pop_tween.finished
	self.visible = false

func _kill_tween_if_valid(tween: Tween) -> void :
	if tween and tween.is_valid():
		tween.kill()

func _set_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween

func _update_current_play_info(raw_length: float) -> void:
	super(raw_length)
	time_played_label.text = AppTool.duration_to_timestamp(raw_length)

func toggle_slider_visibility() -> void:
	if not volume_slider_popup.visible:
		volume_slider_popup.pop_in()
	else:
		volume_slider_popup.pop_out()

func show_extra_details(on: bool) -> void:
	if on:
		_kill_tween_if_valid(_detail_tween)
		_detail_tween = _set_tween()
		var song_panel_offset_x: float = abs(song_panel.size.x / 2.0) * -1
		var detail_panel_offset_x: float = abs(extra_details_panel.size.x ) * -1
		_detail_tween.tween_property(song_panel, "offset_transform_position", Vector2(song_panel_offset_x, 0.0), animation_duration)
		_detail_tween.tween_property(extra_details_panel, "offset_transform_position", Vector2(detail_panel_offset_x, 0.0), animation_duration)
	else:
		_kill_tween_if_valid(_detail_tween)
		_detail_tween = _set_tween()
		_detail_tween.tween_property(song_panel, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
		_detail_tween.tween_property(extra_details_panel, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
