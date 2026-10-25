class_name SceneBase
extends Control

var _bus: EventBus


## Sets up the event bus this object will use for any cross system operations
func set_bus(bus: EventBus) -> void:
	_bus = bus
	_configure()


func _configure() -> void:
	return
