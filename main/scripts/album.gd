class_name Album
extends EntryData

@export var artist: String
@export var release_year: int
@export var songs: Dictionary[int, Song]
@export var number_of_songs: int:
	get ():
		return songs.size()
