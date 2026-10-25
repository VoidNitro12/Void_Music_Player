class_name EventBus
extends RefCounted

var audio: AudioBus

var ui: UiBus

var data: DataBus

var redirect: RedirectBus

func set_up()-> void:
	audio = AudioBus.new()
	ui = UiBus.new()
	data = DataBus.new()
	redirect = RedirectBus.new()
