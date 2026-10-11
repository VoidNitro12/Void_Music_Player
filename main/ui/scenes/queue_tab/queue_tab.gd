class_name QueueTab
extends Panel

@export var hide_btn: Button
@export var queue_list: VBoxContainer
@export var queue_btn_group: ButtonGroup

var _look_up: Dictionary[int, MiniEntry]


func _ready() -> void:
	hide_btn.pressed.connect(
		func() -> void:
			self.visible = false,
	)
	AppEvents.ui.queue_change.connect(update_queue)
	AppEvents.audio.play_song.connect(update_btn_toggles)


func update_queue(
	new_queue: Dictionary[int, QueueItem],
	head: QueueItem,
	current_play: RequestObj,
) -> void:
	for id: int in _look_up.keys():
		if not new_queue.has(id):
			var entry: MiniEntry = _look_up[id]
			queue_list.remove_child(entry)
			entry.queue_free()
			_look_up.erase(id)

	var item: QueueItem = head
	var idx: int = 0
	while item != null:
		var entry: MiniEntry
		if _look_up.has(item.id):
			entry = _look_up[item.id]
		else:
			entry = BaseUi.MINI_ENTRY_SCEME.instantiate()
			queue_list.add_child(entry)
			_look_up[item.id] = entry
		entry.set_data(
			RequestObj.new(item.song, item.song_context_type, item.song_source_id, item.id),
			queue_btn_group,
		)
		if queue_list.get_child(idx) != entry:
			queue_list.move_child(entry, idx)
		item = item.next
		idx += 1
	if current_play != null:
		update_btn_toggles(current_play)


func update_btn_toggles(data: RequestObj) -> void:
	if not _look_up.has(data.queue_id):
		# if not in queue then playing the song will cause a rebuild of the queue
		return
	var entry: MiniEntry = _look_up[data.queue_id]
	entry.action_btn.button_pressed = true
	entry.grab_focus()
