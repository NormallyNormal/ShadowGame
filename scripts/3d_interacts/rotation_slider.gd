extends StaticBody3D

var dragging := false
var drag_start_angle := 0.0
var drag_start_rotation := 0.0

@export var max_rotation_speed := 5.0

var _target_rotation := 0.0
var _current_rotation := 0.0
var _initial_basis := Basis.IDENTITY

func _ready():
	input_event.connect(_on_input_event)
	_initial_basis = global_basis
	_current_rotation = 0.0
	_target_rotation = 0.0

func _on_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start_rotation = _current_rotation
			drag_start_angle = _get_angle_from_mouse(event.position)
		else:
			dragging = false

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
	if dragging and event is InputEventMouseMotion:
		var current_angle = _get_angle_from_mouse(event.position)
		var delta_angle = current_angle - drag_start_angle
		_target_rotation = drag_start_rotation + delta_angle

func _process(delta: float):
	if not dragging:
		return
	var diff = _target_rotation - _current_rotation
	diff = fmod(diff + PI, TAU) - PI
	var max_step = max_rotation_speed * delta
	_current_rotation += clampf(diff, -max_step, max_step)
	global_basis = _initial_basis * Basis(Vector3.UP, _current_rotation)

func get_local_axis() -> Vector3:
	return global_basis.y.normalized()

func _get_angle_from_mouse(mouse_pos: Vector2) -> float:
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var axis_dir = get_local_axis()
	var axis_origin = global_position
	var plane = Plane(axis_dir, axis_origin)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	if intersection == null:
		return 0.0
	var offset = intersection - axis_origin
	var cam_right = camera.global_basis.x.normalized()
	var plane_x = (cam_right - axis_dir * cam_right.dot(axis_dir)).normalized()
	var plane_y = axis_dir.cross(plane_x).normalized()
	return atan2(offset.dot(plane_y), offset.dot(plane_x))
