class_name Playlist
extends EntryData
## Resource for a created Playlist

## Date the playlist was created
@export var date_created: int

## Optional description of the playlist
@export var description: String

## Number of songs in the playlist
@export var number_of_songs: int:
	get ():
		return songs.size()

## Songs in this playlist referenced by id
@export var songs: Dictionary[int, Song]
