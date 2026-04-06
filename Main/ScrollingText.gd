extends Label
class_name Marquee

var scroll_speed = 0.1
var is_scrolling = false

func check_and_scroll():
	var text_width = get_combined_minimum_size().x
	var container_width = size.x
	
	if text_width > container_width:
		is_scrolling = true
		start_scroll()

func start_scroll():
	clip_text = true
	var to_add = []
	var title = text
	var index = 1
	var direction = 1 
	while is_scrolling:
		if direction == 1:
			horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			text = title.substr(index)
			index += 1
			await get_tree().create_timer(scroll_speed).timeout
			if index > len(title):
				to_add = []
				text = ""
				direction = -1
		elif direction == -1:
			horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			index = 1
			for c in title:
				if is_scrolling:
					to_add.append(c)
					var total = "".join(to_add)
					text = total
					await get_tree().create_timer(scroll_speed).timeout
			direction = 1

func stop_scroll():
	clip_text = false
	is_scrolling = false
	text = ""
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
