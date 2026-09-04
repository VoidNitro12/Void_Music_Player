class_name AppTool
extends RefCounted

static func float_to_timestamp(raw_length: float) -> String: 
	var minutes: int = floor(raw_length/60.0)
	var seconds: int = int(raw_length) % 60
	var song_length: String = "%02d:%02d" % [minutes,seconds]
	return song_length
