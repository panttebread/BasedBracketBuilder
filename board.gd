class_name Board extends Control

const BOARD_RES = "res://boards/"
const BOARD_EXT = ".json"

signal bracket_added(bracket_name: String)
signal bracket_removed(bracket_name: String)

var points : Array[PointNode] = []
var brackets : Array[Bracket] = []

func _init() -> void:
	child_entered_tree.connect(_on_child_entered)

func _on_child_entered(child: Node) -> void:
	if child is PointNode:
		points.append(child)
		child.connecting.connect(_on_point_connecting)
		child.disconnecting.connect(_on_point_disconnecting)
		child.bracket_added.connect(_on_bracket_added)

func _on_point_connecting(point: PointNode, external: bool) -> void:
	# find PointNode at mouse position
	for connection_point in points:
		if connection_point.get_global_rect().has_point(get_global_mouse_position()):
			# don't continue if points already connected
			if point.connection_to == connection_point:
				return
			# add connection point to point
			if external:
				point.add_external_connection(connection_point)
			else:
				point.add_connection(connection_point)

func _on_point_disconnecting(point: PointNode) -> void:
	# find PointNode at mouse position
	for connection_point in points:
		if connection_point.get_global_rect().has_point(get_global_mouse_position()):
			# remove connection if connected node selected
			if connection_point.connection_to == point:
				print("removing ",point.name," from ",connection_point.name)
				connection_point.remove_connection()
			elif connection_point.external_connections_to.values().has(point):
				connection_point.remove_external_connection(point)
			return
	# remove all connections if nothing selected
	print("removing all connections to ",point.name)
	for connection_point in point.connections_from:
		connection_point.remove_connection()
	for connection_point in point.external_connections_from:
		connection_point.remove_external_connection(point)
	

func _on_bracket_added(bracket: Bracket) -> void:
	brackets.append(bracket)
	bracket_added.emit(bracket.name)
	bracket.empty.connect(_on_bracket_empty)

func _on_bracket_empty(bracket: Bracket) -> void:
	brackets.remove_at(brackets.find(bracket))
	bracket_removed.emit(bracket.name)
	bracket.empty.disconnect(_on_bracket_empty)

func _find_bracket_by_name(bracket: Bracket, bracket_name: String) -> bool:
	return bracket.name == bracket_name

func rename_bracket(bracket_name: String, new_name: String) -> void:
	var idx = brackets.find_custom(_find_bracket_by_name.bind(bracket_name))
	if idx != -1:
		brackets[idx].name = new_name

func get_dictionary() -> Dictionary:
	var dict:= { "points":[], "brackets":[] }
	
	for i in points.size():
		dict.points.append(points[i].get_dictionary())
		dict.points[i].connection_to = points.find(points[i].connection_to)
		for point in points[i].external_connections_to.values():
			dict.points[i].external_connections_to.append(points.find(point))
	
	for bracket in brackets:
		dict.brackets.append(bracket.name)
	
	return dict

func unpack_dictionary(dict: Dictionary) -> void:
	for bracket_name in dict.brackets:
		var bracket = Bracket.new()
		bracket.name = bracket_name
		_on_bracket_added(bracket)
	
	for point_ref : Dictionary in dict.points:
		var point:= PointNode.new_instance()
		point.position = Vector2(point_ref.position[0], point_ref.position[1])
		point.index = point_ref.index
		var bracket_idx = brackets.find_custom(_find_bracket_by_name.bind(point_ref.bracket))
		if bracket_idx != -1:
			point.bracket = brackets[bracket_idx]
		add_child(point)
	
	for i in dict.points.size():
		var point_ref : Dictionary = dict.points[i]
		if point_ref.connection_to != -1:
			points[i].bypass_add_connection(points[point_ref.connection_to])
		for idx in point_ref.external_connections_to:
			points[i].add_external_connection(points[idx])
	
	for point in points:
		point.queue_redraw.call_deferred()

func clear() -> void:
	for point in points:
		point.queue_free()
	points = []
	brackets = []
