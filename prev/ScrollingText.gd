extends Control

@onready var label: Label = $CurrentSongTitleLabel

var tween: Tween
var is_scrolling = false

func check_and_scroll():
	await get_tree().process_frame
	var text_width = label.get_combined_minimum_size().x
	var container_width = size.x
	
	if text_width > container_width and not is_scrolling:
		start_marquee(text_width, container_width)
	elif text_width <= container_width:
		pass
		

func start_marquee(text_width: float, container_width: float):
	is_scrolling = true
	clip_contents = true
	label.position.x = 0
	
	var distance = text_width + container_width
	var duration = distance / 50.0  # 50 pixels per second, constant speed
	
	tween = create_tween()
	tween.tween_property(label, "position:x", -text_width, duration)
	tween.finished.connect(_loop_marquee.bind(text_width, container_width))

func _loop_marquee(text_width: float, container_width: float):
	label.position.x = container_width
	var distance = text_width + container_width
	var duration = distance / 50.0
	tween = create_tween()
	tween.tween_property(label, "position:x", -text_width, duration)
	tween.finished.connect(_loop_marquee.bind(text_width, container_width))

func stop_marquee():
	if tween:
		tween.kill()
	is_scrolling = false
	label.position.x = 0.0 
	label.offset_left = 0
	label.offset_right = 0
