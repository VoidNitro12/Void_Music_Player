class_name ContextMenu
extends PopupMenu
## Context menu the app used for [EntryData] derived classes

## Id collection used for adding and handling [PopupMenu] items
enum MenuId {
	PLAY_SONG, ## Play a song
	SHOW_INFO, ## Show the info of an EntryData derived Resource
	OPEN_PACKED_ENTRY, ## Open the contents of an Album or Playlist
	DELETE_PLAYLIST, ## Deletes the given playlist
	EDIT_PLAYLIST, ## Opens the edit menu for the given playlist
	REMOVE_SONG_FROM_QUEUE, ## Removes the song from the current queue
	ADD_SONG_TO_QUEUE, ## Adds the song to the end of the current queue
	PLAY_NEXT, ## Moves the song as the next in line item of the queue or adds it as such
	SHOW_IN_FILE_MANAGER, ## Opens the folder where the song file was found
}


func _ready() -> void:
	popup_hide.connect(
		func() -> void:
			self.queue_free(),
	)


## Sets up the container with relevant data.
func set_data(data_obj: RequestObj) -> void:
	if data_obj.entry_data is Song:
		add_item("Play Song", MenuId.PLAY_SONG)
		add_item("Show Info", MenuId.SHOW_INFO)
		if not AppState.audio_handler.context.is_cursor_on_item(data_obj.queue_id):
			# Its harmless but currently this would do nothing if the song is currently
			# playing (cursor is on it)
			add_item("Play Next", MenuId.PLAY_NEXT)
		if data_obj.queue_id != -1: # If true its coming from within a queue
			# this is fine even if the cursor is on it
			add_item("Remove from Queue", MenuId.REMOVE_SONG_FROM_QUEUE)
		else: # Not from a queue
			add_item("Add to Queue", MenuId.ADD_SONG_TO_QUEUE)
		add_item("Show in Files", MenuId.SHOW_IN_FILE_MANAGER)
	elif data_obj.entry_data is Playlist:
		add_item("Open Playlist", MenuId.OPEN_PACKED_ENTRY)
		add_item("Show Info", MenuId.SHOW_INFO)
		add_item("Edit Playlist", MenuId.EDIT_PLAYLIST)
		add_item("Delete Playlist", MenuId.DELETE_PLAYLIST)
	elif data_obj.entry_data is Album:
		add_item("Open Album", MenuId.OPEN_PACKED_ENTRY)
		add_item("Show Info", MenuId.SHOW_INFO)

	id_pressed.connect(_on_menu_pressed.bind(data_obj))


func _on_menu_pressed(id: int, data_obj: RequestObj) -> void:
	match id as MenuId:
		MenuId.PLAY_SONG:
			AppEvents.audio.play_song.emit(data_obj)
		MenuId.SHOW_INFO:
			AppEvents.ui.show_entry_info_popup.emit(data_obj.entry_data)
		MenuId.OPEN_PACKED_ENTRY:
			AppEvents.ui.open_packed_entry.emit(data_obj.entry_data)
		MenuId.DELETE_PLAYLIST:
			AppEvents.ui.confirm_action.emit(
				AppTool.ConfirmationType.DELETE_PLAYLIST,
				func() -> void:
					AppEvents.data.delete_playlist.emit(data_obj.entry_data.storage_id),
			)
		MenuId.EDIT_PLAYLIST:
			AppEvents.ui.edit_playlist.emit(data_obj.entry_data.id)
		MenuId.REMOVE_SONG_FROM_QUEUE:
			AppEvents.audio.remove_song_from_queue.emit(data_obj.queue_id)
		MenuId.ADD_SONG_TO_QUEUE:
			AppEvents.audio.add_song_to_queue.emit(data_obj)
		MenuId.PLAY_NEXT:
			AppEvents.audio.play_next.emit(data_obj)
		MenuId.SHOW_IN_FILE_MANAGER:
			OS.shell_show_in_file_manager(data_obj.entry_data.path)
		_:
			AppEvents.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Invalid menu id %d in context menu",
			)
