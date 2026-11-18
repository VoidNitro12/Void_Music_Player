@abstract
class_name VirtualScroll
extends ScrollContainer

@export var item_scene: PackedScene

## Extra rows to keep alive above and below the viewport.
@export var overscan: int = 3

@export var spacing: int = 0

var _entry_set_template: ItemData
var _data: Array[RequestObj] = []
var _pool: Array[ContainerEntry] = []
var _node_lookup: Dictionary[int, ContainerEntry] = {}
var _status_lookup: Dictionary[String, Dictionary]
var _content: Control
var _bus: EventBus

func set_bus(bus: EventBus) -> void:
	_bus = bus

func _ready() -> void:
	_content = get_child(0)

func set_data(items: Array[RequestObj], template_data: ItemData, data_detail: Dictionary[String, Dictionary]) -> void:
	_data = items
	_entry_set_template = template_data
	_status_lookup = data_detail

func populate_row(entry: ContainerEntry , index: int) -> void:
	entry.set_data(_data[index], 
			_entry_set_template.is_selection, 
			_entry_set_template.display_only,
			_entry_set_template.btn_group
	)
	
	if _status_lookup.has(_data[index].entry_data.uuid):
		entry.set_btn_selection(_status_lookup[_data[index].entry_data.uuid]["selected"])

func is_empty() -> bool:
	return _data.is_empty()

func get_content_minimum_size_on_axis() -> float:
	return 0.0

func _on_scroll(_value: float) -> void:
	_refresh()

func _refresh() -> void:
	pass

func _get_or_create_item() -> ContainerEntry:
	if _pool.size() > 0:
		return _pool.pop_back()
	var entry: ContainerEntry = item_scene.instantiate()
	entry.set_bus(_bus)
	_content.add_child(entry)
	return entry
