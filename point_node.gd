class_name PointNode extends PanelContainer

const SCENE_RES = "res://point_node.tscn"

static func new_instance() -> PointNode:
	return load(SCENE_RES).instantiate()

signal connecting(point: PointNode, external: bool)
signal disconnecting(point: PointNode)
signal bracket_added(new_bracket: Bracket)

@export var index : int:
	set(value): index = value; _set_index.call_deferred(value)

func _set_index(value: int) -> void:
	#if not is_instance_valid(index_box):
		#await ready
	%IndexBox.value = value

var bracket : Bracket:
	set(value):
		if is_instance_valid(value):
			#if not is_instance_valid(bracket_label):
				#await ready
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
			_break_external_connections()
		bracket = value

@onready var index_box : SpinBox = %IndexBox
@onready var bracket_label : Label = %BracketLabel

var connection_to : PointNode
var connections_from : Array[PointNode] = []
var external_connections_to : Dictionary[Bracket, PointNode] = {}
var external_connections_from : Array[PointNode] = []

var _moving : bool
var _connecting : bool
var _disconnecting : bool
var _external_connecting : bool

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _moving:
		global_position = get_global_mouse_position() - _get_connect_button_position()
		queue_redraw()
		for point in connections_from + external_connections_from:
			point.queue_redraw()
	elif event.is_action_released("node_select"):
		if _moving:
			_moving = false
			%MoveButton.release_focus()
		elif _connecting:
			_connecting = false
			connecting.emit(self, false)
			%ConnectToButton.release_focus()
		elif _external_connecting:
			_external_connecting = false
			connecting.emit(self, true)
			%ConnectExternalButton.release_focus()
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
	for point in external_connections_to.values():
		draw_polyline([
			get_external_connect_to_position(),
			point.get_connect_from_position() - position
		], Color.BLUE, 1.0)

func get_dictionary() -> Dictionary:
	var dict = {
		"position": [position.x, position.y],
		"index": index,
		"bracket": "",
		"connection_to": -1,
		"external_connections_to": []
	}
	
	if is_instance_valid(bracket):
		dict.bracket = bracket.name
	
	return dict

func get_connect_to_position() -> Vector2:
	return %ConnectToButton.size * 0.5 + %ConnectToButton.global_position - position

func get_connect_from_position() -> Vector2:
	return global_position + %ConnectFromButton.size * 0.5 + %ConnectFromButton.position
	#return %ConnectFromButton.size * 0.5 + %ConnectFromButton.global_position - position

func get_external_connect_to_position() -> Vector2:
	return %ConnectExternalButton.size * 0.5 + %ConnectExternalButton.global_position - position
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
func _on_connect_external_button_down() -> void: _external_connecting = true

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
	
	bypass_add_connection(point)
	return Error.OK

func bypass_add_connection(point: PointNode) -> void:
	connection_to = point
	point._add_connection_from(self)
	queue_redraw()

func _add_connection_from(point: PointNode) -> void:
	connections_from.append(point)

func add_external_connection(point: PointNode) -> Error:
	if not is_instance_valid(bracket) or not is_instance_valid(point.bracket):
		return ERR_INVALID_PARAMETER
	if point.bracket == bracket:
		return ERR_CYCLIC_LINK
	external_connections_to[point.bracket] = point
	point.external_connections_from.append(self)
	queue_redraw()
	return OK

func remove_external_connection(point: PointNode) -> void:
	if external_connections_to.has(point.bracket):
		external_connections_to.erase(point.bracket)
		point._remove_external_connection_from.call_deferred(self)
		queue_redraw()

func _remove_external_connection_from(point: PointNode) -> void:
	var idx:= external_connections_from.find(point)
	if idx != -1:
		external_connections_from.remove_at(idx)

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

func _break_external_connections() -> void:
	for point in external_connections_from:
		point.external_connections_to.erase(bracket)
		point.queue_redraw()

func _add_to_bracket(new_bracket: Bracket) -> void:
	bracket = new_bracket
	for point in connections_from:
		point._add_to_bracket(new_bracket)
