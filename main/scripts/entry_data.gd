class_name EntryData
extends Resource

@export var id: int

@export var title: String

@export var cover_path: String

@export var cover: ImageTexture:
	get ():
		return _get_cover()

func _get_cover() -> ImageTexture:
	var image: Image = Image.new()
	
	if not FileAccess.file_exists(self.cover_path):
		push_error("Song cover not found")
		image.load("res://icon.svg") #TODO change to a set "no cover" image when gotten
		return ImageTexture.create_from_image(image)
	
	
	image.load(self.cover_path)
	return ImageTexture.create_from_image(image)
