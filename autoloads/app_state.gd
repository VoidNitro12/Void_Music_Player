extends Node
## Autoload class to store references to data used across the system

var app_version: String

var event_bus: EventBus

var error_logger: ErrorLogger

var file_scanner: FileScanner

var save_system: SaveSystem

var id_manager: IdManager

var audio_handler: AudioHandler

var settings: Settings

var stats: Stats

var theme_manager: ThemeManager

var library: Library

var session_id: String

var is_shutting_down: bool = false

func _ready() -> void:
	Bootstrap.start_up()

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or is_shutting_down == true:
		return
	
	is_shutting_down = true
	Bootstrap.shut_down()
