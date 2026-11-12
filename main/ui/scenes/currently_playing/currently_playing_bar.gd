class_name CurrentlyPlayingBar
extends BaseCurrentPlayingBar

## Bottom bar for displaying info on the currently playing song

@export_group("Info")
@export var song_info_btn: Button

@export_group("Controls")
@export var volume_btn: IconBtn
@export var _slider_popup: VolumeSliderPopup
@export var hide_btn: IconBtn

var _slide_tween: Tween

var current_playing_song: Song  #NOTE: exists already in AudioHandler, just don't wanna reach into it

var animation_duration: float = 0.9

## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	if data == null:
		return
	if data.entry_data == null:
		return
	super(data)
	var song: Song = data.entry_data
	current_playing_song = song
	_slide_in()


func _configure() -> void:
	super()
	_slider_popup.set_bus(_bus)
	volume_btn.set_bus(_bus)
	hide_btn.set_bus(_bus)

	song_info_btn.pressed.connect(_on_song_info_pressed)

	volume_btn.pressed.connect(toggle_slider_visibility)
	
	hide_btn.pressed.connect(_slide_out)


func _on_song_info_pressed() -> void:
	if current_playing_song == null:
		return
	_bus.ui.show_entry_info_popup.emit(current_playing_song)


func toggle_slider_visibility() -> void:
	if not _slider_popup.visible:
		_slider_popup.pop_in()
	else:
		_slider_popup.pop_out()
		
func _slide_out() -> void:
	_kill_tween_if_valid()
	_set_tween()
	var off_point_x: float = abs(self.size.y + (self.size.y / 3)) # Its size and a bit more
	_slide_tween.tween_property(self, "offset_transform_position", Vector2(0.0, off_point_x), animation_duration)
	_slide_tween.tween_property(self, "offset_transform_scale", Vector2(0.3, 1.0), animation_duration)
	await _slide_tween.finished
	self.visible = false
	# considering making this fully stop playback instead of say adding an extra btn to slide it back in if needed

func _slide_in() -> void:
	_kill_tween_if_valid()
	_set_tween()
	self.visible = true
	_slide_tween.tween_property(self, "offset_transform_position", Vector2(0.0, 0.0), animation_duration)
	_slide_tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), animation_duration)

func _kill_tween_if_valid() -> void :
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()

func _set_tween() -> void:
	_slide_tween = create_tween()
	_slide_tween.set_parallel(true)
	_slide_tween.set_trans(Tween.TRANS_EXPO)
	_slide_tween.set_ease(Tween.EASE_IN_OUT)