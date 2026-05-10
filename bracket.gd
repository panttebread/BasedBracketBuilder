class_name Bracket extends Resource

static var count : int = 0

signal empty(bracket: Bracket)

var name : String
var points : Array[PointNode]

func _init(bracket_points: Array[PointNode] = []) -> void:
	count += 1
	name = str("bracket",count)
	for point in bracket_points:
		point.bracket = self

func add_point(point: PointNode) -> Error:
	if not is_instance_valid(point):
		return ERR_INVALID_PARAMETER
	if points.has(point):
		return ERR_ALREADY_EXISTS
	points.append(point)
	return OK

func remove_point(point: PointNode) -> void:
	var idx:= points.find(point)
	if idx != -1:
		points.remove_at(idx)
		if points.is_empty():
			empty.emit(self)
