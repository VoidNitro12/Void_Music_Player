class_name QueueTab
extends Panel

const QUEUE_ENTRY_SCENE: PackedScene = preload("res://main/ui/scenes/queue_tab/QueueEntry.tscn")

@export var hide_btn: Button
@export var queue_list: VBoxContainer
@export var queue_btn_group: ButtonGroup

var _look_up: Dictionary[int, QueueEntry]


func _ready() -> void:
	hide_btn.pressed.connect(
		func() -> void:
			self.visible = false,
	)
	AppEvents.ui.queue_change.connect(update_queue)
	AppEvents.audio.play_song.connect(update_btn_toggles)


func update_queue(new_queue: Dictionary[int, Song]) -> void:
	for id: int in _look_up.keys():
		if not new_queue.has(id):
			var entry: QueueEntry = _look_up[id]
			queue_list.remove_child(entry)
			entry.queue_free()
			_look_up.erase(id)

	var index: int = 0
	for song: Song in new_queue.values():
		var entry: QueueEntry
		if _look_up.has(song.id):
			entry = _look_up[song.id]
		else:
			entry = QUEUE_ENTRY_SCENE.instantiate()
			queue_list.add_child(entry)
			_look_up[song.id] = entry
		entry.set_data(song, queue_btn_group)
		if queue_list.get_child(index) != entry:
			queue_list.move_child(entry, index)
		index += 1


func update_btn_toggles(data: RequestObj) -> void:
	if not _look_up.has(data.entry_data.id):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Requested update in update_btn_toggles is not in queue, audio handler's queues 
			may not be properly setup",
		)
		return
	var entry: QueueEntry = _look_up[data.entry_data.id]
	entry.action_btn.button_pressed = true
	entry.grab_focus()
