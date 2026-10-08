class_name ConfirmDialog
extends ConfirmationDialog

func _ready() -> void:
	canceled.connect(func()->void: self.queue_free())

func set_data(type: AppTool.ConfirmationType, confirm_action: Callable) -> void:
	if confirm_action == null:
		return
	self.show()
	match type:
		AppTool.ConfirmationType.DELETE_PLAYLIST:
			title = "Delete Playlist?"
			dialog_text = "Playlist will be permamently deleted from disk"
			confirmed.connect(confirm_action)
