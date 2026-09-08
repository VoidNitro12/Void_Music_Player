class_name Playlist
extends EntryData

@export var date_created: int
@export var description: String
@export var number_of_songs: int:
	get ():
		return songs.size()
@export var songs: Dictionary[int, Song]
