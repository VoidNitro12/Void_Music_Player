class_name BaseCurrentPlayingBar
extends Panel

const PLAY_ICON: CompressedTexture2D = preload("res://assets/icons/play_btn.svg")
const PAUSE_ICON: CompressedTexture2D = preload("res://assets/icons/pause_btn.svg")

@export_group("Info")
@export var image_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label

@export_group("Controls")
@export var shuffle_btn: Button
@export var prev_btn: Button
@export var play_pause_btn: Button
@export var next_btn: Button
@export var loop_btn: Button

@export_subgroup("Seeker")
@export var seeker: HSlider

var _seeker_is_dragged: bool = false

func _ready() -> void:
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
			AppEvents.audio.prev_song.emit(),
	)
	next_btn.pressed.connect(
		func() -> void:
			AppEvents.audio.next_song.emit(),
	)


	AppEvents.audio.play_song.connect(set_currently_playing)
	AppEvents.ui.update_current_play_info.connect(_update_current_play_info)
	AppEvents.ui.song_is_playing.connect(change_pause_play_icon)

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
		AppEvents.audio.seek_song.emit(seeker.value)
	_seeker_is_dragged = false

func _on_pause_play_pressed() -> void:
	AppEvents.audio.pause_play_music.emit()


func _on_shuffle_pressed(toggled: bool) -> void:
	AppEvents.audio.shuffle_queue.emit(toggled)


func _on_loop_pressed(toggled: bool) -> void:
	AppEvents.audio.loop_song.emit(toggled)
