class_name Bracket extends Resource

static var count : int = 0

signal name_changed(new_name: String)
signal empty(bracket: Bracket)

@export var name : String:
	set(value):
		if name != value:
			name_changed.emit(value)
			name = value
var points : Array[PointNode]

func _init(bracket_points: Array[PointNode] = []) -> void:
	count += 1
	name = str("bracket",count)
	for i in bracket_points.size():
		bracket_points[i].index = i
		bracket_points[i].bracket = self

func add_point(point: PointNode) -> Error:
	if not is_instance_valid(point):
		return ERR_INVALID_PARAMETER
	if points.has(point):
		return ERR_ALREADY_EXISTS
	point.index = points.size()
	points.append(point)
	return OK

func remove_point(point: PointNode) -> void:
	var idx:= points.find(point)
	if idx != -1:
		points.remove_at(idx)
		if points.is_empty():
			empty.emit(self)

func get_dictionary() -> Dictionary:
	var bracket_dict : Dictionary
	
	for point in points:
		if not is_instance_valid(point.connection_to):
			bracket_dict = _fill_dict_recursive({}, point, -1)
			break
	
	var keys = bracket_dict.keys()
	keys.reverse()
	var lowest_level = keys.min() * -1
	
	for key in keys:
		bracket_dict[key + lowest_level] = bracket_dict[key]
		bracket_dict.erase(key)
	
	return bracket_dict

func _fill_dict_recursive(dict: Dictionary, point: PointNode, level: int) -> Dictionary:
	if not dict.has(level):
		dict[level] = []
	
	var point_dict:= { "index": point.index }
	if is_instance_valid(point.connection_to):
		point_dict[point.bracket.name] = point.connection_to.index
	for ext_bracket in point.external_connections_to:
		point_dict[ext_bracket.name] = point.external_connections_to[ext_bracket].index
	
	dict[level].append(point_dict)
	
	point.connections_from.sort_custom(_sort_by_position)
	for connection in point.connections_from:
		dict = _fill_dict_recursive(dict, connection, level-1)
	return dict

func _sort_by_position(a: PointNode, b: PointNode) -> bool:
	return a.position.x < b.position.x
