@tool
extends StaticBody3D

var dragging := false
var drag_start_angle := 0.0
var drag_start_rotation := 0.0
var mouse_in = false
@export var max_rotation_speed := 10.0
@export var color: Colors.ColorID = Colors.ColorID.WHITE:
	set(value):
		color = value
		$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.COLOR_VALUES_MAX[color])

var _target_rotation := 0.0
var _current_rotation := 0.0
var _initial_basis := Basis.IDENTITY

func _ready():
	if Engine.is_editor_hint():
		$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.COLOR_VALUES_MAX[color])
		return
	$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.get_color(color))
	if Engine.is_editor_hint():
		return
	input_event.connect(_on_input_event)
	_initial_basis = global_basis
	_current_rotation = 0.0
	_target_rotation = 0.0

func _on_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not Colors.is_enabled(color):
				dragging = false
				drag_start_angle = 0.0
				drag_start_rotation = _current_rotation
				_target_rotation = _current_rotation
				return
			dragging = true
			drag_start_rotation = _current_rotation
			drag_start_angle = _get_angle_from_mouse(event.position)
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		else:
			dragging = false

func _on_mouse_exited():
	mouse_in = false
	if not dragging:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_mouse_entered():
	if not Colors.is_enabled(color):
		return
	mouse_in = true
	
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		if not mouse_in:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if dragging and event is InputEventMouseMotion:
		var current_angle = _get_angle_from_mouse(event.position)
		var delta_angle = current_angle - drag_start_angle
		_target_rotation = drag_start_rotation + delta_angle

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.get_color(color))
	if not Colors.is_enabled(color):
		dragging = false
		return
		
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

func _mouse_intersects(mouse_pos: Vector2) -> float:
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var axis_dir = get_local_axis()
	var axis_origin = global_position
	var plane = Plane(axis_dir, axis_origin)
	return plane.intersects_ray(ray_origin, ray_dir) != null
