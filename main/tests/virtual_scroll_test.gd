extends Control


func _ready() -> void:
	var detail: Dictionary[String, Dictionary]
	$VirtualScrollVertical.set_data(_get_mock_objs(10000), ItemData.new(false, false, null), detail)
	$VirtualScrollHorizontal.set_data(_get_mock_objs(10000), ItemData.new(false, false, null), detail)
	
func _get_mock_objs(num: int) -> Array[RequestObj]:
	var results: Array[RequestObj] = []
	for i: int in range(num):
		var song: Song = Song.new()
		song.uuid = str(i)
		song.title = "Title %d" % i
		song.artist = "Artist %d" % i
		
		var obj: RequestObj = RequestObj.new(song, AppTool.ContextType.SONG)
		results.append(obj)
	
	return results
