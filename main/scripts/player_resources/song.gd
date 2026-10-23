class_name Song
extends EntryData
## Resource for a discovered audio file used by the app

## Artist of the song
@export var artist: String = ""

## Album this song belongs too
@export var album: String = ""

## Year this song was released
@export var release_year: int = 0

## Duration of this song
@export var raw_length: int = 0

## Location of the song on the user's directory
@export var path: String = ""
