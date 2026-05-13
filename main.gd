extends Control


## To-do:
## - confirm overwrite on save

## Bugs:
## - Brackets don't get added to board when a node with multiple connections is disconnected from
##   a node
## - Single nodes connected to a removed node get new bracket


# Called when the node enters the scene tree for the first time.
func _ready():
	%VersionLabel.text = "v" + ProjectSettings.get_setting("application/config/version")
	DisplayServer.window_set_min_size(Vector2i(
		%BoardViewContainer.custom_minimum_size.x,
		$HBoxContainer.get_combined_minimum_size().y
	))
	%ToolBox.size.x = 200
	#get_tree().root.min_size = Vector2i(%ToolBox.get_combined_minimum_size())
	%ToolBox.custom_minimum_size.y = %ToolBox.get_combined_minimum_size().y
	
	%Board.bracket_added.connect(_on_bracket_added)
	%Board.bracket_removed.connect(_on_bracket_removed)

func _on_add_point_button_pressed():
	%Board.add_point_at_camera()

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

func _on_new_button_pressed():
	if %Board.has_board_changed():
		_board_to_be_loaded = ""
		%SaveConfirmDialog.popup_with_name(%NameEdit.text)
	else:
		_on_save_confirm_dialog_confirm_continue()

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

func _on_save_confirm_dialog_save(board_name):
	var old_name = %NameEdit.text
	%NameEdit.text = board_name
	_on_save_button_pressed()
	%NameEdit.text = old_name

var _board_to_be_loaded : String

func _on_load_button_pressed():
	%LoadDialog.popup()

func _on_load_dialog_confirmed():
	var selected : PackedInt32Array = %BoardList.get_selected_items()
	if selected.size() > 0:
		_board_to_be_loaded = %BoardList.get_item_text(%BoardList.get_selected_items()[0])
		if %Board.has_board_changed():
			%SaveConfirmDialog.popup_with_name(%NameEdit.text)
		else:
			_on_save_confirm_dialog_confirm_continue()
	else:
		%MessagePopup.display_message("No file selected")

func _on_save_confirm_dialog_confirm_continue():
	load_board(_board_to_be_loaded)
	_board_to_be_loaded = ""

func _on_save_confirm_dialog_canceled():
	_board_to_be_loaded = ""

func _get_filename(board_name: String) -> String:
	return Board.BOARD_RES+board_name+Board.BOARD_EXT

func save_board(board_name: String) -> Error:
	if board_name == "":
		return ERR_FILE_BAD_PATH
	#if %Board.points.is_empty():
		#return ERR_DOES_NOT_EXIST
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
	%Board.board_changed = false
	return OK

func load_board(board_name: String) -> void:
	%NameEdit.text = board_name
	%BracketList.clear()
	%Board.clear()
	Bracket.count = 0
	if board_name != "":
		var string:= FileAccess.get_file_as_string(_get_filename(board_name))
		if string != null:
			var json = JSON.parse_string(string)
			if json != null:
				%Board.unpack_dictionary(json)
			if json.version != ProjectSettings.get_setting("application/config/version"):
				%MessagePopup.display_message(
					str("WARNING: board was made with different version (v", json.version, ")")
				)

func _on_export_button_pressed():
	if %NameEdit.text != "":
		%ExportJSONDialog.current_file = %NameEdit.text #".json"
	else:
		%ExportJSONDialog.current_file = "untitled" #"untitled.json"
	%ExportJSONDialog.popup()
	#var dict:= {}
	#for bracket in %Board.brackets:
		#dict[bracket.name] = bracket.get_dictionary()
	#print(dict)

func _on_export_json_dialog_file_selected(path: String) -> void:
	var dict:= {}
	for bracket in %Board.brackets:
		dict[bracket.name] = bracket.get_export_dictionary()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(dict, "\t"))
		%MessagePopup.display_message("File exported successfully")
	else:
		%MessagePopup.display_message("Couldn't export to file")
	file.close()

func _on_user_dir_button_pressed():
	if not DirAccess.dir_exists_absolute(Board.BOARD_RES):
		DirAccess.make_dir_absolute(Board.BOARD_RES)
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Board.BOARD_RES))

#endregion
