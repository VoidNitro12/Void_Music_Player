class_name Stats
extends RefCounted
## Class for keeping track of player use data

## Max number of songs [member songs_played] will keep track of
var max_songs_played: int = 30

## Array of songs that have being played. What counts as played depends on
## [AudioHandler.seconds_till_played]
var songs_played: Array[Song]

## Appends a song to the [member songs_played] list and ensures it doesnt surpass
## [member max_songs_played]
func add_to_songs_played(song: Song) -> void: 
	songs_played.append(song)
	if songs_played.size() > max_songs_played:
		songs_played.pop_front()
