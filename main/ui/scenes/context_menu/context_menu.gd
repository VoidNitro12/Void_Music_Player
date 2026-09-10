class_name ContextMenu
extends PopupMenu
## Context menu the app used for [EntryData] derived classes

## Id collection used for adding and handling [PopupMenu] items
enum MenuId {
	PLAY_SONG, ## Play a song
	SHOW_INFO, ## Show the info of an EntryData derived Resource
	OPEN_PACKED_ENTRY, ## Open the contents of an Album or Playlist
}

func _ready() -> void:
	popup_hide.connect(func()->void: self.queue_free())

## Sets up the container with relevant data.
func set_data(data_obj: RequestObj) -> void:
	if data_obj.entry_data is Song:
		add_item("Play Song", MenuId.PLAY_SONG)
		add_item("Show Info", MenuId.SHOW_INFO)
	elif data_obj.entry_data is Playlist:
		add_item("Open Playlist", MenuId.OPEN_PACKED_ENTRY)
		add_item("Show Info", MenuId.SHOW_INFO)
	elif data_obj.entry_data is Album:
		add_item("Open Album", MenuId.OPEN_PACKED_ENTRY)
		add_item("Show Info", MenuId.SHOW_INFO)

	id_pressed.connect(_on_menu_pressed.bind(data_obj))


func _on_menu_pressed(id: int, data_obj: RequestObj) -> void:
	match id as MenuId:
		MenuId.PLAY_SONG:
			AppEvents.play_song.emit(data_obj)
		MenuId.SHOW_INFO:
			AppEvents.show_entry_info_popup.emit(data_obj)
		MenuId.OPEN_PACKED_ENTRY:
			AppEvents.open_packed_entry.emit(data_obj.entry_data)
