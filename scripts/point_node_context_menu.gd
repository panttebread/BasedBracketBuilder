extends PopupMenu


@onready var point_node : PointNode = get_parent()


func _on_about_to_popup():
	if is_instance_valid(point_node.bracket):
		set_item_disabled(0, false)
	else:
		set_item_disabled(0, true)


func _on_index_pressed(index):
	match index:
		0: # Remove
			_remove()
		1: # Delete
			_remove()
			point_node.queue_free()

func _remove() -> void:
	if is_instance_valid(point_node.bracket):
		point_node._break_all_connections()
