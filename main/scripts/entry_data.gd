class_name EntryData
extends Resource
## Base class for [Song], [Playlist] and [Album]

## Id of the entry
@export var id: int = -1

## Title of the entry
@export var title: String = ""

## Location of the cover image of the entry
@export var cover_path: String = ""

## Cover image of the entry
@export var cover: Texture2D:
	get ():
		return _get_cover()


func _get_cover() -> Texture2D:
	var image: Image = Image.new()

	if not FileAccess.file_exists(self.cover_path):
		AppEvents.data.log_error.emit(
			ErrorLogger.LogLevel.WARN,
			"Cover not found for file \"%s\", using placeholder" % self.title,
		)
		return preload("res://assets/icons/default_cover.svg") 
	

	image = Image.load_from_file(self.cover_path)
	return ImageTexture.create_from_image(image)
