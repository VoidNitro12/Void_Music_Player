class_name Playlist
extends EntryData
## Resource for a created Playlist

## Date the playlist was created
@export var date_created: String:
	get(): 
		#TODO change to a settings option for format
		return "%s/%s/%s"%[date_dict.day,date_dict.month,date_dict.year] 

## Optional description of the playlist
@export var description: String

## Number of songs in the playlist
@export var number_of_songs: int:
	get ():
		return songs.size()

## Songs in this playlist referenced by id
@export var songs: Dictionary[int, Song]

## Raw creation date data
@export var date_dict: Dictionary[String, int] = {
	"day": 0,
	"month": 0,
	"year": 0,
	"weekday": 0,
}
