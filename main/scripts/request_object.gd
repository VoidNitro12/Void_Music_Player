class_name RequestObj
extends RefCounted
## Data holder for all relevant info needed between systems for easy transfer

var entry_data: EntryData
var source: AppTool.MainTabSections
var source_id: int

func _init(p_data: EntryData, p_source: AppTool.MainTabSections, p_source_id: int) -> void:
	entry_data = p_data
	source = p_source
	source_id =p_source_id
