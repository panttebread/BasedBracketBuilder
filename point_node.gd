class_name PointNode extends PanelContainer


signal connecting(point: PointNode)
signal disconnecting(point: PointNode)
signal bracket_added(new_bracket: Bracket)

@export var index : int:
	get: return %IndexBox.value
	set(value): %IndexBox.value = value

var bracket : Bracket:
	set(value):
		if is_instance_valid(value):
			if value.points.is_empty():
				bracket_added.emit(value)
			value.add_point(self)
			value.name_changed.connect(_on_bracket_name_changed)
			%BracketLabel.text = value.name
		else:
			%BracketLabel.text = ""
		if is_instance_valid(bracket):
			bracket.remove_point(self)
			bracket.name_changed.disconnect(_on_bracket_name_changed)
		bracket = value

var connection_to : PointNode
var connections_from : Array[PointNode] = []

var _moving : bool
var _connecting : bool
var _disconnecting : bool

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _moving:
		global_position = get_global_mouse_position() - _get_connect_button_position()
		queue_redraw()
		for point in connections_from:
			point.queue_redraw()
	elif event.is_action_released("node_select"):
		if _moving:
			_moving = false
			%MoveButton.release_focus()
		elif _connecting:
			_connecting = false
			connecting.emit(self)
			%ConnectToButton.release_focus()
		elif _disconnecting:
			_disconnecting = false
			disconnecting.emit(self)
			%ConnectFromButton.release_focus()

func _draw() -> void:
	if is_instance_valid(connection_to):
		draw_polyline([
			get_connect_to_position(),
			connection_to.get_connect_from_position() - position
		], Color.WHITE, 1.0)

func get_connect_to_position() -> Vector2:
	return %ConnectToButton.size * 0.5 + %ConnectToButton.global_position - position

func get_connect_from_position() -> Vector2:
	return global_position + %ConnectFromButton.size * 0.5 + %ConnectFromButton.position
	#return %ConnectFromButton.size * 0.5 + %ConnectFromButton.global_position - position

func get_center_top() -> Vector2:
	return Vector2(position.x + size.x * 0.5, position.y)

func _get_connect_button_position() -> Vector2:
	return %MoveButton.size * 0.5 + %MoveButton.position

func _on_bracket_name_changed(new_name: String) -> void:
	%BracketLabel.text = new_name

func _on_move_button_button_down() -> void: _moving = true
func _on_connect_to_button_down() -> void: _connecting = true
func _on_connect_from_button_down() -> void: _disconnecting = true

func add_connection(point: PointNode) -> Error:
	# don't continue if point invalid
	if point == self or connection_to == point or not is_instance_valid(point):
		return ERR_INVALID_PARAMETER
	# don't continue if connecting to self
	if connections_from.has(point):
		return ERR_CYCLIC_LINK
	# don't continue if connecting to node in same bracket
	if bracket != null and bracket == point.bracket:
		return ERR_CYCLIC_LINK
	
	# remove previous connection
	if is_instance_valid(connection_to):
		remove_connection()
	
	# connect points to same bracket prioritising the bracket of the node we're
	# connecting to
	if is_instance_valid(point.bracket):
		_add_to_bracket(point.bracket)
	elif is_instance_valid(bracket):
		point.bracket = bracket
	else:
		Bracket.new([self, point])
		#var new_bracket:= Bracket.new([self, point])
		#bracket_added.emit(Bracket.new([self, point]))
	
	connection_to = point
	point._add_connection_from(self)
	queue_redraw()
	return Error.OK

func _add_connection_from(point: PointNode) -> void:
	connections_from.append(point)

func remove_connection() -> void:
	connection_to._remove_connection_from.call_deferred(self)
	connection_to = null
	_remove_from_bracket()
	queue_redraw()

func _remove_connection_from(point: PointNode) -> void:
	var idx:= connections_from.find(point)
	if idx != -1:
		connections_from.remove_at(idx)
		_check_bracket()

func _check_bracket() -> void:
	if connections_from.is_empty() and not is_instance_valid(connection_to):
		bracket = null

func _remove_from_bracket() -> void:
	if not connections_from.is_empty():
		var new_bracket:= Bracket.new()
		#bracket_added.emit(new_bracket)
		for point in connections_from:
			_add_to_bracket(new_bracket)
	elif not is_instance_valid(connection_to):
		bracket = null

func _add_to_bracket(new_bracket: Bracket) -> void:
	bracket = new_bracket
	for point in connections_from:
		point._add_to_bracket(new_bracket)
