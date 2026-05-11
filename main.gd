extends Control


## To-do:
## - connect nodes between brackets
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

func _on_dictionary_button_pressed():
	%Board.brackets[0].get_dictionary()


func _on_bracket_options_bracket_name_changed(from, to):
	%Board.rename_bracket(from, to)
