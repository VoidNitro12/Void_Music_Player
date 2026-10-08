class_name Settings
extends RefCounted
## Class for holding all option related data

#-----------------File Scanning----------------
## All currently loaded directories
var loaded_paths: PackedStringArray

## Whether to scan only the submited folder or also any directories it contains
var scan_subdirs: bool = false
