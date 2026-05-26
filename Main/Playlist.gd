class_name  Playlist
extends Resource

@export var id: int
@export var title: String
@export var date_created: String
@export var number_of_songs: int = 0
@export var songs: Array

func _init(playlist_id: int = -1, playlist_title: String = "", playlist_date_created: String = "") -> void:
	self.id = playlist_id
	self.title = playlist_title
	self.date_created = playlist_date_created

func update_song_count()-> void: 
	self.number_of_songs = self.songs.size()
