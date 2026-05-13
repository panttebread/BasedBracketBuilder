class_name Board extends Control

const BOARD_RES = "user://boards/"
const BOARD_EXT = ".json"
const CAMERA_PAN_SPEED = 0.01
const CAMERA_ZOOM_SPEED = 0.1
const CAMERA_ZOOM_MIN = 0.7
const CAMERA_ZOOM_MAX = 1.5

static var snap_to_grid:= true

signal bracket_added(bracket_name: String)
signal bracket_removed(bracket_name: String)
signal camera_panning(pos: Vector2)
signal camera_zooming(zoom: float)

var board_changed : bool

var points : Array[PointNode] = []
var brackets : Array[Bracket] = []

@onready var camera : Camera2D = $Camera2D
@onready var grid : ColorRect = $GridRect

func _init() -> void:
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)

func _on_child_entered(child: Node) -> void:
	if child is PointNode:
		points.append(child)
		child.connecting.connect(_on_point_connecting)
		child.disconnecting.connect(_on_point_disconnecting)
		child.index_changed.connect(_on_point_index_changed)
		child.moving.connect(_on_point_moving)
		child.bracket_added.connect(_on_bracket_added)

func _on_child_exiting(child: Node) -> void:
	if child is PointNode and points.has(child):
		points.remove_at(points.find(child))

func _ready() -> void:
	grid.material.set_shader_parameter(&"cell_size", float(PointNode.GRID_SIZE))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("camera_pan"):
			camera.position -= event.relative
			camera_panning.emit(camera.position)
	elif event.is_action_pressed("camera_zoom_in"):
		var zoom = camera.zoom + Vector2(CAMERA_ZOOM_SPEED, CAMERA_ZOOM_SPEED)
		if zoom.x > CAMERA_ZOOM_MAX:
			zoom = Vector2(CAMERA_ZOOM_MAX, CAMERA_ZOOM_MAX)
		camera.zoom = zoom
		camera_zooming.emit(zoom.x)
	elif event.is_action_pressed("camera_zoom_out"):
		var zoom = camera.zoom - Vector2(CAMERA_ZOOM_SPEED, CAMERA_ZOOM_SPEED)
		if zoom.x < CAMERA_ZOOM_MIN:
			zoom = Vector2(CAMERA_ZOOM_MIN, CAMERA_ZOOM_MIN)
		camera.zoom = zoom
		camera_zooming.emit(zoom.x)
	_resize_grid()

func _resize_grid() -> void:
	grid.size = get_viewport_rect().size / camera.zoom
	grid.position = camera.position - grid.size * 0.5

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
			board_changed = true

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
			board_changed = true
			return
	# remove all connections if nothing selected
	print("removing all connections to ",point.name)
	for connection_point in point.connections_from:
		connection_point.remove_connection()
	for connection_point in point.external_connections_from:
		connection_point.remove_external_connection(point)
	board_changed = true
	

func _on_point_index_changed(_from: int, _to: int) -> void:
	board_changed = true

func _on_point_moving(moving_point: PointNode, pos: Vector2) -> void:
	var moving_rect:= Rect2(pos, moving_point.size)
	for point in points:
		if point == moving_point:
			continue
		moving_point.position = _snap_to_points(
			point.get_global_rect(),
			moving_point.get_global_rect()
		).position

func _snap_to_points(snap_rect: Rect2, pos_rect: Rect2) -> Rect2:
	#var pos:= pos_rect.position
	if snap_rect.intersects(pos_rect):
		var offset = snap_rect.get_center() - get_global_mouse_position()
		pos_rect.position = snap_rect.position
		# should move to left or right
		if abs(offset.x) > abs(offset.y):
			if offset.x > 0: pos_rect.position.x -= snap_rect.size.x
			else: pos_rect.position.x = snap_rect.end.x
		else:
			if offset.y > 0: pos_rect.position.y -= snap_rect.size.y
			else: pos_rect.position.y = snap_rect.end.y
	return pos_rect

func _lines_intersect(a_pos: float, a_end: float, b_pos: float, b_end: float) -> bool:
	var intersects : bool
	
	if b_pos <= a_pos: intersects = true
	if a_pos < b_end: intersects = true
	if b_pos <= a_end: intersects = true
	if a_end < b_end: intersects = true
	
	return intersects

func _on_bracket_added(bracket: Bracket) -> void:
	brackets.append(bracket)
	bracket_added.emit(bracket.name)
	bracket.empty.connect(_on_bracket_empty)
	board_changed = true

func _on_bracket_empty(bracket: Bracket) -> void:
	brackets.remove_at(brackets.find(bracket))
	bracket_removed.emit(bracket.name)
	bracket.empty.disconnect(_on_bracket_empty)
	board_changed = true

func _find_bracket_by_name(bracket: Bracket, bracket_name: String) -> bool:
	return bracket.name == bracket_name

func add_point() -> void:
	add_child(PointNode.new_instance())

func add_point_at_camera() -> void:
	var point = PointNode.new_instance()
	point.snap(camera.position - point.get_center())
	add_child(point)

func rename_bracket(bracket_name: String, new_name: String) -> void:
	var idx = brackets.find_custom(_find_bracket_by_name.bind(bracket_name))
	if idx != -1:
		brackets[idx].name = new_name
	board_changed = true

func get_dictionary() -> Dictionary:
	var dict:= {
		"version": ProjectSettings.get_setting("application/config/version"),
		"points":[],
		"brackets":[],
		"camera": {
			"position": [camera.position.x, camera.position.y],
			"zoom": [camera.zoom.x, camera.zoom.y]
		}
	}
	
	for i in points.size():
		dict.points.append(points[i].get_dictionary())
		dict.points[i].connection_to = points.find(points[i].connection_to)
		for point in points[i].external_connections_to.values():
			dict.points[i].external_connections_to.append(points.find(point))
	
	for bracket in brackets:
		dict.brackets.append(bracket.get_dictionary())
	
	return dict

func unpack_dictionary(dict: Dictionary) -> void:
	for bracket_dict in dict.brackets:
		var bracket = Bracket.new()
		bracket.name = bracket_dict.name
		bracket.color = Color(bracket_dict.color[0], bracket_dict.color[1], bracket_dict.color[2])
		bracket.is_loading = true
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
	
	for bracket in brackets:
		bracket.is_loading = false
	
	camera.position = Vector2(dict.camera.position[0], dict.camera.position[1])
	camera.zoom = Vector2(dict.camera.zoom[0], dict.camera.zoom[1])
	
	camera_panning.emit(camera.position)
	camera_zooming.emit(camera.zoom.x)
	
	_reset_board_changed.call_deferred()

func _reset_board_changed() -> void:
	board_changed = false

func has_board_changed() -> bool:
	return board_changed

func clear() -> void:
	for point in points:
		point.queue_free()
	points = []
	brackets = []
	board_changed = false
