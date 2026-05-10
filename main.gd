extends Control


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
