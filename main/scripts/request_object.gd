class_name RequestObj
extends RefCounted
## Data holder for all relevant info needed between systems for easy transfer

## Data being sent
var entry_data: EntryData

## Section location of the entry
var source: AppTool.MainTabSections

## Id of the data's source. [code]-1[/code]  if from not playlist or album else is the id of said
## container
var source_id: int = -1

func _init(p_data: EntryData, p_source: AppTool.MainTabSections, p_source_id: int) -> void:
	entry_data = p_data
	source = p_source
	source_id =p_source_id
