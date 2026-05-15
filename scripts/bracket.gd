class_name Bracket extends Resource

const PANEL_BOX_RES = "res://theme/panel_style_box.tres"
const ALPHA = 0.97
const NULL_COLOR = Color(0.133, 0.161, 0.176, 0.97)
const COLORS = [
	Color(0.086, 0.208, 0.251, 0.97),
	Color(0.291, 0.126, 0.2, 0.97),
	Color(0.101, 0.18, 0.355, 0.97),
	Color(0.212, 0.189, 0.122, 0.97),
	Color(0.276, 0.152, 0.121, 0.97),
	Color(0.108, 0.215, 0.173, 0.97),
	Color(0.238, 0.137, 0.308, 0.97),
	Color(0.175, 0.15, 0.37, 0.97)
]

static var count : int = 0

signal name_changed(new_name: String)
signal empty(bracket: Bracket)

@export var name : String:
	set(value):
		if name != value:
			name_changed.emit(value)
			name = value
@export var color : Color:
	set(value):
		value.a = ALPHA
		if is_instance_valid(_style_box):
			_style_box.bg_color = value
			for point in points:
				point._style_box = _style_box
			color = value
var points : Array[PointNode]
var is_loading : bool

var _style_box : StyleBox

func _init(bracket_points: Array[PointNode] = []) -> void:
	count += 1
	name = str("bracket",count)
	_style_box = load(PANEL_BOX_RES).duplicate()
	color = COLORS[count % COLORS.size()-1]
	for i in bracket_points.size():
		bracket_points[i].index = i
		bracket_points[i].bracket = self

func add_point(point: PointNode) -> Error:
	if not is_instance_valid(point):
		return ERR_INVALID_PARAMETER
	if points.has(point):
		return ERR_ALREADY_EXISTS
	if not is_loading:
		point.index = points.size()
	point.index_changed.connect(_on_point_index_changed)
	points.append(point)
	return OK

func remove_point(point: PointNode) -> void:
	var idx:= points.find(point)
	if idx != -1:
		point.index_changed.disconnect(_on_point_index_changed)
		points.remove_at(idx)
		if points.is_empty():
			empty.emit(self)

func get_dictionary() -> Dictionary:
	return {
		"name": name,
		"color": [color.r, color.g, color.b]
	}

func get_export_dictionary() -> Dictionary:
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

func _on_point_index_changed(point: PointNode, prev_index: int) -> void:
	if is_loading:
		return
	for other_point in points:
		if point == other_point:
			continue
		if other_point.index == point.index:
			other_point.index = prev_index
			break
