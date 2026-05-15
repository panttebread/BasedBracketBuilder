extends AcceptDialog

@onready var message_label = $MessageLabel

func display_message(message: String) -> void:
	message_label.text = message
	popup()
