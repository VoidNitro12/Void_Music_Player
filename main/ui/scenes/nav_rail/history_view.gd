class_name HistoryView
extends Panel

@export var view_container: VBoxContainer

func _ready() -> void:
	AppEvents.ui.updated_recently_played.connect(_fill_view_container)

func _fill_view_container(songs: Array[Song]) -> void: 
	songs.reverse() # last items come up on top
	
	# No need for a render func its like 30 nodes max that arent meant to be reused or
	# moved 
	for child: Node in view_container.get_children():
		child.queue_free()
	
	for song: Song in songs: 
		var entry: MiniEntry = BaseUi.MINI_ENTRY_SCEME.instantiate()
		view_container.add_child(entry)
		entry.set_data(RequestObj.new(song, AppTool.ContextType.SONG))
