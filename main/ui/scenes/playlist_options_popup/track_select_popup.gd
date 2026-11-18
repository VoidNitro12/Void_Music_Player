class_name TrackSelectPopup
extends Window

signal selections_confirmed(songs: Dictionary[String, Song])

@export_group("Tracks to Select Section")
@export var search_bar: LineEdit
@export var songs_found_count: Label
@export var songs_found_container: VirtualScrollVertical

@export_group("Selected Tracks Section")
@export var selected_songs_count: Label
@export var clear_selected_btn: LinkButton
@export var selected_songs_container: VirtualScrollVertical
@export var confirm_btn: Button

var selections: Dictionary[String, Song]

var _bus: EventBus

var _library: Library


func _ready() -> void:
	close_requested.connect(
		func() -> void:
			self.queue_free(),
	)
	search_bar.text_changed.connect(search_entries)


# Though im making it to be re-useable, just gonna design it specifically for playlists,
# till I have an actual second use case
func set_data(existing_songs: Dictionary[String, Song], bus: EventBus, library: Library) -> void:
	_bus = bus
	_library = library
	fill_songs_found(existing_songs)
	confirm_btn.pressed.connect(confirm_selections)
	clear_selected_btn.pressed.connect(clear_selections)


func fill_songs_found(existing_songs: Dictionary[String, Song]) -> void:
	pass
	songs_found_container
	for song: Song in _library.get_all_tracks().values():
		pass

	songs_found_count.text = "%d Songs found" % _library.get_all_tracks().values().size()


func confirm_selections() -> void:
	selections_confirmed.emit(selections)
	close_requested.emit()

func edit_selections(add: bool, id: String, song: Song) -> void:
	pass


func clear_selections() -> void:
	pass

	selections.clear()
	selected_songs_count.text = "Selected Songs (0)"


func search_entries(text: String) -> void:
	var children: Array[Node] = songs_found_container.get_children()
	for child: Node in children:
		if child is ContainerEntry:
			child.visible = (
				child.in_search(ContainerEntry.SortType.SEARCH_TITLE, text)
				or child.in_search(ContainerEntry.SortType.SEARCH_ARTIST, text)
			)
		else:
			_bus.data.log_error.emit(
				ErrorLogger.LogLevel.ERROR,
				"Unexpected Type %s found in a container in track select found songs"
				% [child.get_class()],
			)


func _get_node_id_by_song_id(id: String, container: VBoxContainer) -> int:
	var child_idx: int = container.get_children().find_custom(
		func(node: Node) -> bool:
			return node.name == str(id),
	)
	return child_idx
