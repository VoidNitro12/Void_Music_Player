@abstract
class_name VirtualScroll
extends ScrollContainer

@export var item_scene: PackedScene

## Extra rows to keep alive above and below the viewport.
@export var overscan: int = 3

@export var spacing: int = 0

@export var reversed: bool = true

var _data: Array[RequestObj] = []
var _pool: Array[ContainerEntry] = []
var _lookup: Dictionary[int, ContainerEntry] = {}
var _content: Control

func _ready() -> void:
	_content = get_child(0)

func set_data(items: Array) -> void:
	_data = items

func populate_row(entry: ContainerEntry , index: int) -> void:
	entry.set_data(_data[index])

func _on_scroll(_value: float) -> void:
	_refresh()

func _refresh() -> void:
	pass

func _get_or_create_item() -> ContainerEntry:
	if _pool.size() > 0:
		return _pool.pop_back()
	var entry: ContainerEntry = item_scene.instantiate()
	entry.set_bus(EventBus.new())
	_content.add_child(entry)
	return entry
