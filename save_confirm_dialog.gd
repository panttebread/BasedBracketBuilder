extends AcceptDialog

signal save(board_name: String)
signal confirm_continue

@onready var name_edit = $VBoxContainer/SaveConfirmNameEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	add_button("Save", false, "save")

func _on_custom_action(action):
	if action == "save":
		save.emit(name_edit.text)
		if name_edit.text != "":
			confirm_continue.emit()
		hide()

func _on_confirmed():
	confirm_continue.emit()

func popup_with_name(board_name: String) -> void:
	name_edit.text = board_name
	popup()
