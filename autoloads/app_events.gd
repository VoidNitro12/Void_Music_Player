extends Node
## Event bus for cross system communication

# A signal needing RequestObj means it's receivers need context
# While just EntryData means they don't require it

func _ready() -> void:
	audio = AudioBus.new()
	ui = UiBus.new()
	data = DataBus.new()

var audio: AudioBus

var ui: UiBus

var data: DataBus
