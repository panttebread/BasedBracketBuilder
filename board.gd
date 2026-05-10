extends Control

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

func _on_point_connecting(point: PointNode) -> void:
	# find PointNode at mouse position
	for connection_point in points:
		if connection_point.get_global_rect().has_point(get_global_mouse_position()):
			# don't continue if points already connected
			if point.connection_to == connection_point:
				return
			# don't continue if point wasn't able to be connected
			if point.add_connection(connection_point) != OK:
				return
			print("connecting ",point.name," to ",connection_point.name)
			# add one to the other's bracket
			if is_instance_valid(point.bracket):
				connection_point.bracket = point.bracket
			elif is_instance_valid(connection_point.bracket):
				point.bracket = connection_point.bracket
			# or make a new bracket if neither have one
			else:
				_on_bracket_added(Bracket.new([point, connection_point]))

func _on_point_disconnecting(point: PointNode) -> void:
	# find PointNode at mouse position
	for connection_point in points:
		if connection_point.get_global_rect().has_point(get_global_mouse_position()):
			# remove connection if connected node selected
			if connection_point.connection_to == point:
				print("removing ",point.name," from ",connection_point.name)
				connection_point.remove_connection()
			return
	# remove all connections if nothing selected
	print("removing all connections to ",point.name)
	for connection_point in point.connections_from:
		connection_point.remove_connection()

func _on_bracket_added(bracket: Bracket) -> void:
	brackets.append(bracket)
	bracket_added.emit(bracket.name)
	bracket.empty.connect(_on_bracket_empty)

func _on_bracket_empty(bracket: Bracket) -> void:
	brackets.remove_at(brackets.find(bracket))
	bracket_removed.emit(bracket.name)
	bracket.empty.disconnect(_on_bracket_empty)
