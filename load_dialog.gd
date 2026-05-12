extends ConfirmationDialog

@onready var board_list = $VBoxContainer/BoardList
@onready var board_filter = $VBoxContainer/BoardFilter

var boards : PackedStringArray

#func _ready() -> void:
	#find_boards()

func find_boards() -> void:
	boards.clear()
	board_list.clear()
	for file in DirAccess.get_files_at(Board.BOARD_RES):
		var board = file.get_basename()
		boards.append(board)
		board_list.add_item(board)

func _on_about_to_popup() -> void:
	find_boards()
	board_filter.text = ""
	board_filter.grab_focus.call_deferred()

func _on_board_filter_text_changed(new_text: String) -> void:
	board_list.clear()
	for board in boards:
		if board.contains(new_text) or new_text == "":
			board_list.add_item(board)
