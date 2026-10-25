class_name HistoryView
extends SceneBase

@export var view_container: VBoxContainer

func _configure() -> void:
	_bus.ui.updated_recently_played.connect(_fill_view_container)

func _fill_view_container(songs: Array[Song]) -> void: 
	# No need for a render function, its like 30 nodes max that aren't meant to be reused or
	# moved 
	for child: Node in view_container.get_children():
		child.queue_free()
	
	for song: Song in songs: 
		var entry: MiniEntry = BaseUi.MINI_ENTRY_SCEME.instantiate()
		view_container.add_child(entry)
		entry.set_bus(_bus)
		entry.set_data(RequestObj.new(song, AppTool.ContextType.SONG))
