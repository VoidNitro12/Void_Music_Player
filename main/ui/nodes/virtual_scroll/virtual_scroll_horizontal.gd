class_name VirtualScrollHorizontal
extends VirtualScroll

@export var item_width: float = 60.0

func _ready() -> void:
	get_h_scroll_bar().value_changed.connect(_on_scroll)

func set_data(items: Array[RequestObj], template_data: ItemData, data_detail: Dictionary[String, Dictionary]) -> void:
	super(items, template_data, data_detail)
	_content.custom_minimum_size.x = _data.size() * (item_width + spacing)
	_refresh()

func _refresh() -> void:
	var scroll_x  :float = get_h_scroll_bar().value
	var viewport_w :float = size.x
	var pitch: int = int(item_width + spacing) # So spacing doesn't break

	var first : int = max(0, int(scroll_x / pitch) - overscan) # index of the first visible item
	var last : int = min(_data.size()-1, int((scroll_x + viewport_w) / pitch) + overscan) # index of the last visible item

	# Recycle rows that are now out of range.
	for idx: int in _node_lookup.keys():
		if idx < first or idx > last:
			var col: ContainerEntry  = _node_lookup[idx]
			_node_lookup.erase(idx)
			_pool.append(col)
			col.visible = false

	# Assign rows for newly visible indices.
	for idx: int in range(first, last + 1):
		if _node_lookup.has(idx):
			continue
		var col : ContainerEntry  = _get_or_create_item()
		_node_lookup[idx] = col
		col.position.x = idx * pitch
		col.visible = true
		populate_row(col, idx)

func get_control_minimum_size_of_axis() -> float:
	return _content.custom_minimum_size.x