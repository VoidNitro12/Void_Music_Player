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
@export var cover: ImageTexture:
	get ():
		return _get_cover()


func _get_cover() -> ImageTexture:
	var image: Image = Image.new()

	if not FileAccess.file_exists(self.cover_path):
		push_warning("cover not found, using placeholder")
		image.load("res://icon.svg") #TODO change to a set "no cover" image and use load_from_file
		return ImageTexture.create_from_image(image)

	image = Image.load_from_file(self.cover_path)
	return ImageTexture.create_from_image(image)
