class_name BaseCurrentPlayingBar
extends SceneBase

const PLAY_ICON: CompressedTexture2D = preload("res://assets/icons/play_icon.svg")
const PAUSE_ICON: CompressedTexture2D = preload("res://assets/icons/pause_icon.svg")

@export_group("Info")
@export var image_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label

@export_group("Controls")
@export var shuffle_btn: IconBtn
@export var prev_btn: IconBtn
@export var play_pause_btn: IconBtn
@export var next_btn: IconBtn
@export var loop_btn: IconBtn

@export_subgroup("Seeker")
@export var seeker: HSlider

var _seeker_is_dragged: bool = false

func _configure() -> void:
	seeker.drag_started.connect(
		func() -> void:
			_seeker_is_dragged = true,
	)
	seeker.drag_ended.connect(_seek_music)

	shuffle_btn.toggled.connect(_on_shuffle_pressed)
	loop_btn.toggled.connect(_on_loop_pressed)
	play_pause_btn.pressed.connect(_on_pause_play_pressed)
	prev_btn.pressed.connect(
		func() -> void:
			_bus.audio.prev_song.emit(),
	)
	next_btn.pressed.connect(
		func() -> void:
			_bus.audio.next_song.emit(),
	)
	
	shuffle_btn.set_bus(_bus)
	loop_btn.set_bus(_bus)
	play_pause_btn.set_bus(_bus) 
	prev_btn.set_bus(_bus) 
	next_btn.set_bus(_bus)


	_bus.audio.play_song.connect(set_currently_playing)
	_bus.ui.update_current_play_info.connect(_update_current_play_info)
	_bus.ui.song_is_playing.connect(change_pause_play_icon)

## Sets data for the received song for fields
func set_currently_playing(data: RequestObj) -> void:
	if data == null:
		return
	if not data.entry_data is Song:
		return
	var song: Song = data.entry_data

	image_rect.texture = song.cover
	title_label.text = song.title
	artist_label.text = song.artist
	seeker.max_value = song.raw_length


func change_pause_play_icon(on: bool) -> void:
	if on:
		play_pause_btn.icon = PAUSE_ICON
	else:
		play_pause_btn.icon = PLAY_ICON

func _update_current_play_info(raw_length: float) -> void:
	if not _seeker_is_dragged:
		seeker.value = raw_length

func _seek_music(value_changed: bool) -> void:
	if value_changed:
		_bus.audio.seek_song.emit(seeker.value)
	_seeker_is_dragged = false

func _on_pause_play_pressed() -> void:
	_bus.audio.pause_play_music.emit()


func _on_shuffle_pressed(toggled: bool) -> void:
	_bus.audio.shuffle_queue.emit(toggled)


func _on_loop_pressed(toggled: bool) -> void:
	_bus.audio.loop_song.emit(toggled)
