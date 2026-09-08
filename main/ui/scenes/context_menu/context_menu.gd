class_name ContextMenu
extends PopupMenu

func _ready() -> void:
	pass

func set_data(data_obj: RequestObj) -> void: 
	
	if data_obj.entry_data is Song:
		add_item("Play Song", 0)
		add_item("Show Info", 1)
	elif data_obj.entry_data is Playlist:
		pass
	
	id_pressed.connect(_on_menu_pressed.bind(data_obj))

func _on_menu_pressed(id: int, data_obj: RequestObj) -> void: 
	if data_obj.entry_data is Song:
		match id: 
			0:
				AppEvents.play_song.emit(data_obj)
			1:
				AppEvents.show_entry_info_popup.emit(data_obj)
