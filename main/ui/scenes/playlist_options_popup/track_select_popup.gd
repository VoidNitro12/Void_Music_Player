class_name TrackSelectPopup
extends Window

@export_group("Tracks to Select Section")
@export var search_bar: LineEdit
@export var songs_found_count: Label
@export var songs_found_container: VBoxContainer

@export_group("Selected Tracks Section")
@export var selected_songs_count: Label
@export var clear_selected_btn: LinkButton
@export var selected_songs_container: VBoxContainer
@export var confirm_btn: Button

signal selections_confirmed(songs: Dictionary[int, Song])

var selections: Dictionary[int, Song]

func _ready() -> void:
	close_requested.connect(
		func() -> void:
			self.queue_free(),
	)


# Though im making it to be reuseable, just gonna design it specifically for playlists,
# till I have an actual second usecase
func set_data(existing_songs: Dictionary[int, Song]) -> void:
	fill_songs_found(existing_songs)
	confirm_btn.pressed.connect(confirm_selections)
	clear_selected_btn.pressed.connect(clear_selections)


func fill_songs_found(existing_songs: Dictionary[int, Song]) -> void:
	for song: Song in AppState.all_tracks.values():
		var entry: ContainerEntry = FullScreenPlayer.CONTAINER_ENTRY_SCENE.instantiate()
		entry.set_data(RequestObj.new(song, AppTool.MainTabSections.NONE, -1), true)
		entry.change_view_type(ContainerEntry.ViewType.LIST)
		entry.selection_checkbox.toggled.connect(edit_selections.bind(song.id, song))
		if existing_songs.has(song.id):
			entry.selection_checkbox.button_pressed = true
		entry.name = str(song.id)
		songs_found_container.add_child(entry)

	songs_found_count.text = "%d Songs found" % AppState.all_tracks.values().size()


func confirm_selections() -> void:
	selections_confirmed.emit(selections)
	close_requested.emit()


func edit_selections(add: bool, id: int, song: Song) -> void:
	if add:
		selections[id] = song
		var entry: ContainerEntry = FullScreenPlayer.CONTAINER_ENTRY_SCENE.instantiate()
		entry.set_data(RequestObj.new(song, AppTool.MainTabSections.NONE, -1), false, true)
		entry.change_view_type(ContainerEntry.ViewType.LIST)
		entry.name = str(id)
		selected_songs_container.add_child(entry)
	else:
		if selections.has(id):
			selections.erase(id)
		var child_idx: int = _get_node_id_by_song_id(song.id, selected_songs_container)
		if not child_idx == -1:
			selected_songs_container.get_child(child_idx).free()
	selected_songs_count.text = "Selected Songs (%d)"%selected_songs_container.get_children().size()

func clear_selections() -> void: 
	for song: Song in selections.values(): 
		var child_idx: int = _get_node_id_by_song_id(song.id, songs_found_container)
		if not child_idx == -1:
			var child: ContainerEntry = songs_found_container.get_child(child_idx)
			child.selection_checkbox.set_pressed_no_signal(false)
	
	for child: Node in selected_songs_container.get_children(): 
		child.queue_free()
	
	selected_songs_count.text = "Selected Songs (0)"


func _get_node_id_by_song_id(id: int, container: VBoxContainer) -> int:  
	var child_idx: int = container.get_children().find_custom(
			func(node: Node) -> bool:
				return node.name == str(id),
		)
	return child_idx
	
