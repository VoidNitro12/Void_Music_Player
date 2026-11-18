class_name VirtualScrollVertical
extends VirtualScroll

@export var item_height: float = 60.0

func _ready() -> void:
	get_v_scroll_bar().value_changed.connect(_on_scroll)

func set_data(items: Array[RequestObj], template_data: ItemData, data_detail: Dictionary[String, Dictionary]) -> void:
	super(items, template_data, data_detail)
	_content.custom_minimum_size.y = _data.size() * (item_height + spacing)
	_refresh()

func _refresh() -> void:
	var scroll_y  :float = get_v_scroll_bar().value
	var viewport_h :float = size.y
	var pitch: int = int(item_height + spacing) # So spacing doesn't break

	var first : int = max(0, int(scroll_y / pitch) - overscan) # index of the first visible item
	var last : int = min(_data.size()-1, int((scroll_y + viewport_h) / pitch) + overscan) # index of the last visible item

	# Recycle rows that are now out of range.
	for idx: int in _node_lookup.keys():
		if idx < first or idx > last:
			var row: ContainerEntry  = _node_lookup[idx]
			_node_lookup.erase(idx)
			_pool.append(row)
			row.visible = false

	# Assign rows for newly visible indices.
	for idx: int in range(first, last + 1):
		if _node_lookup.has(idx):
			continue
		var row : ContainerEntry  = _get_or_create_item()
		_node_lookup[idx] = row
		row.position.y = idx * pitch
		row.visible = true
		populate_row(row, idx)

func get_control_minimum_size_of_axis() -> float:
	return _content.custom_minimum_size.y
