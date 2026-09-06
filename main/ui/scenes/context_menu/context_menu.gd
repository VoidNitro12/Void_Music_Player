class_name ContextMenu
extends PopupMenu

var entry_data: EntryData

func _ready() -> void:
	pass

func set_data(data_obj: RequestObj) -> void: 
	
	if data_obj.data is Song:
		add_item("Play Song", 0)
		add_item("Show Info", 1)
	elif data_obj.data is Playlist:
		pass
	
	entry_data = data_obj.data
	id_pressed.connect(_on_menu_pressed.bind(data_obj))

func _on_menu_pressed(id: int, data_obj: RequestObj) -> void: 
	if entry_data is Song:
		match id: 
			0:
				AppEvents.play_song.emit(entry_data, data_obj.source, data_obj.source_id)
			1:
				AppEvents.show_song_info_popup.emit(entry_data)
