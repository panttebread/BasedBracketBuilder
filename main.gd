extends Control


## To-do:
## - Board camera
## - button that adds PointNode
## - enforce unique indexes in brackets
## - export json
## - save/load

## Bugs:
## - Brackets don't get added to board when a node with multiple connections is disconnected from
##   a node


# Called when the node enters the scene tree for the first time.
func _ready():
	%Board.bracket_added.connect(_on_bracket_added)
	%Board.bracket_removed.connect(_on_bracket_removed)


func _on_bracket_added(bracket_name: String) -> void:
	%BracketList.add_item(bracket_name)

func _on_bracket_removed(bracket_name: String) -> void:
	for i in %BracketList.item_count:
		if %BracketList.get_item_text(i) == bracket_name:
			%BracketList.remove_item(i)
			break
	_reset_bracket_count()

func _reset_bracket_count() -> void:
	var max_count : int
	for i in %BracketList.item_count:
		var text : String = %BracketList.get_item_text(i)
		if int(text[-1]) > max_count:
			max_count = int(text[-1])
	Bracket.count = max_count

func _on_bracket_options_bracket_name_changed(from, to):
	%Board.rename_bracket(from, to)

#region File

func _on_save_button_pressed():
	var message : String
	match save_board(%NameEdit.text):
		OK:
			%SaveButton.text = "Saved"
			await get_tree().create_timer(3.0).timeout
			%SaveButton.text = "Save"
			return
		ERR_FILE_BAD_PATH: message = "Can't save without a name"
	%MessagePopup.display_message(message)

func _on_load_button_pressed():
	%LoadDialog.popup()

func _on_load_dialog_confirmed():
	var selected : PackedInt32Array = %BoardList.get_selected_items()
	if selected.size() > 0:
		load_board(%BoardList.get_item_text(selected[0]))
	else:
		%MessagePopup.display_message("No file selected")

func _get_filename(board_name: String) -> String:
	return Board.BOARD_RES+board_name+Board.BOARD_EXT

func save_board(board_name: String) -> Error:
	if board_name == "":
		return ERR_FILE_BAD_PATH
	var dict : Dictionary = %Board.get_dictionary()
	if dict.size() > 0:
		if not DirAccess.dir_exists_absolute(Board.BOARD_RES):
			DirAccess.make_dir_absolute(Board.BOARD_RES)
		var file:= FileAccess.open(_get_filename(board_name), FileAccess.WRITE)
		if file == null:
			print(error_string(FileAccess.get_open_error()))
		else:
			file.store_string(str(dict))
			file.close()
	return OK

func load_board(board_name: String) -> void:
	var string:= FileAccess.get_file_as_string(_get_filename(board_name))
	if string != null:
		%NameEdit.text = board_name
		%BracketList.clear()
		%Board.clear()
		Bracket.count = 0
		var json = JSON.parse_string(string)
		if json != null:
			%Board.unpack_dictionary(json)

func _on_export_button_pressed():
	var dict:= {}
	for bracket in %Board.brackets:
		dict[bracket.name] = bracket.get_dictionary()
	print(dict)

#endregion
