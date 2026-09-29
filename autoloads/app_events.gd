extends Node
## Event bus for cross system communication

# A signal needing RequestObj means it's receivers need context
# While just EntryData means they don't require it

var audio: AudioBus

var ui: UiBus

var data: DataBus
