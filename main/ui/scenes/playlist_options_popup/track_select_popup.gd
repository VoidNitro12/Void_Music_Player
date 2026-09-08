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

var selections: Dictionary[int, Song]


func _ready() -> void:
	close_requested.connect(
		func() -> void:
			self.queue_free(),
	)


# Though im making it to be reuseable, just gonna design it specifically for playlists,
# till I have an actual second usecase
func set_data(playlist_id: int) -> void:
	fill_songs_found()
	confirm_btn.pressed.connect(confirm_selections.bind(playlist_id))


func fill_songs_found() -> void:
	for song: Song in AppState.all_tracks.values():
		var entry: ContainerEntry = FullScreenPlayer.CONTAINER_ENTRY_SCENE.instantiate()
		entry.set_data(RequestObj.new(song, AppTool.MainTabSections.NONE, -1), true)
		entry.change_view_type(ContainerEntry.ViewType.LIST)
		entry.selection_checkbox.toggled.connect(edit_selections.bind(song.id, song))
		songs_found_container.add_child(entry)

	songs_found_count.text = "%d Songs found" % AppState.all_tracks.values().size()


func confirm_selections(playlist_id: int) -> void:
	pass


func edit_selections(add: bool, id: int, song: Song) -> void:
	if add:
		selections[id] = song
		var entry: ContainerEntry = FullScreenPlayer.CONTAINER_ENTRY_SCENE.instantiate()
		entry.set_data(RequestObj.new(song, AppTool.MainTabSections.NONE, -1), true)
		entry.change_view_type(ContainerEntry.ViewType.LIST)
		entry.name = str(id)
		selected_songs_container.add_child(entry)
	else:
		if selections.has(id):
			selections.erase(id)
		var child_idx: int = selected_songs_container.get_children().find_custom(
			func(node: Node) -> bool:
				return node.name == str(id),
		)
		if not child_idx == -1:
			selected_songs_container.get_child(child_idx).queue_free()
