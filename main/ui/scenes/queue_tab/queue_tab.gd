class_name QueueTab
extends Panel

@export var hide_btn: Button
@export var queue_list: VBoxContainer


func _ready() -> void:
	hide_btn.pressed.connect(
		func() -> void:
			self.visible = false,
	)
	AppEvents.queue_change.connect(update_queue)


func update_queue(new_queue: Dictionary[int, Song]) -> void:
	for child: Node in queue_list.get_children():
		if not child is ContainerEntry:
			AppEvents.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Unexpected Type %s found in a container in Queue Tab list" % [child.get_class()],
			)

		child.queue_free()

	var btn_group: ButtonGroup = ButtonGroup.new()

	for song: Song in new_queue.values():
		var entry: ContainerEntry = BaseUi.CONTAINER_ENTRY_SCENE.instantiate()
		entry.set_data(
			RequestObj.new(
				song,
				AudioHandler.current_song_section,
				AudioHandler.current_song_source_id,
			),
			false,
			false,
			btn_group,
		)
		entry.change_view_type(ContainerEntry.ViewType.LIST)
		queue_list.add_child(entry)
