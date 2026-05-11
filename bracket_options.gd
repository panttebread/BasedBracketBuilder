extends PanelContainer


signal bracket_name_changed(from: String, to: String)

@export var bracket_list : ItemList

var _index : int
var _name : String

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("node_select"):
		if not get_global_rect().has_point(event.position):
			hide()

func _on_bracket_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_index = index
		_name = bracket_list.get_item_text(index)
		%NameEdit.text = _name
		position = at_position
		show()


func _on_name_edit_text_changed(new_text: String) -> void:
	bracket_list.set_item_text(_index, new_text)
	bracket_name_changed.emit(_name, new_text)
	_name = new_text


func _on_focus_exited() -> void:
	hide()
