class_name QueueItem
extends RefCounted

var id: int
var song: Song
var song_source_id: int
var song_context_type: AppTool.ContextType
var next: QueueItem
var prev: QueueItem

func get_copy() -> QueueItem:
	var item: QueueItem = QueueItem.new()
	item.id = id
	item.song = song
	item.song_context_type = song_context_type
	item.song_source_id = song_source_id
	
	return item
