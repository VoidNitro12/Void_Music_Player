class_name Album
extends EntryData
## Data Class for grouping songs into their self described albums

## Artist of the album
@export var artist: String

## Release year of the album
@export var release_year: int

## Songs in this album referenced by id
@export var songs: Dictionary[int, Song]

## Number of songs in the album
@export var number_of_songs: int:
	get ():
		return songs.size()
