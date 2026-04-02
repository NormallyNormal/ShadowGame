@tool
extends StaticBody3D

var dragging := false
var drag_start_t := 0.0
var drag_start_position := Vector3.ZERO
var mouse_in = false

@onready var upcap = $UpCap
@onready var downcap = $DownCap

@export var vertical_range : float = 2.0:
	set(value):
		vertical_range = value  # Always store the value first
		if not is_node_ready():
			await ready
		upcap.position.y = vertical_range / 2.0 + 1.0
		downcap.position.y = -vertical_range / 2.0 - 1.0
@export var max_speed := 5.0
@export var color: Colors.ColorID = Colors.ColorID.WHITE:
	set(value):
		color = value
		if is_node_ready():
			$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.COLOR_VALUES_MAX[color])

var target_position := Vector3.ZERO

var cap_world_origin_up := Vector3.ZERO
var cap_world_origin_down := Vector3.ZERO

func _ready():
	if Engine.is_editor_hint():
		$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.COLOR_VALUES_MAX[color])
		return
	$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.get_color(color))
	input_event.connect(_on_input_event)
	target_position = global_position
	upcap.position.y = vertical_range / 2.0 + 1.0
	downcap.position.y = -vertical_range / 2.0 - 1.0
	cap_world_origin_up = upcap.global_position
	cap_world_origin_down = downcap.global_position

func _on_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not Colors.is_enabled(color):
				return
			dragging = true
			drag_start_position = global_position
			drag_start_t = _get_axis_parameter_from_mouse(event.position, drag_start_position)
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
		var current_t = _get_axis_parameter_from_mouse(event.position, drag_start_position)
		var delta_t = current_t - drag_start_t
		var axis = get_local_axis()
		var origin_t = axis.dot(drag_start_position)
		var up_t = axis.dot(cap_world_origin_up - Vector3.UP * global_transform.basis.get_scale().y) - origin_t
		var down_t = axis.dot(cap_world_origin_down + Vector3.UP * global_transform.basis.get_scale().y) - origin_t
		var min_t = min(up_t, down_t)
		var max_t = max(up_t, down_t)
		var clamped_delta = clamp(delta_t, min_t, max_t)
		target_position = drag_start_position + axis * clamped_delta

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	$MeshInstance3D.material_override.set_shader_parameter("emission", Colors.get_color(color))
	if not Colors.is_enabled(color):
		dragging = false
		drag_start_t = 0.0
		drag_start_position = global_position
		target_position = global_position
		return
	var diff = target_position - global_position
	var dist = diff.length()
	if dist >= 0.001:
		var max_step = max_speed * delta
		if dist <= max_step:
			global_position = target_position
		else:
			global_position += diff.normalized() * max_step
	
	upcap.global_position = cap_world_origin_up
	downcap.global_position = cap_world_origin_down

func get_local_axis() -> Vector3:
	return global_basis.y.normalized()

func _get_axis_parameter_from_mouse(mouse_pos: Vector2, axis_origin: Vector3) -> float:
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var axis_dir = get_local_axis()
	var w0 = axis_origin - ray_origin
	var a = axis_dir.dot(axis_dir)
	var b = axis_dir.dot(ray_dir)
	var c = ray_dir.dot(ray_dir)
	var d = axis_dir.dot(w0)
	var e = ray_dir.dot(w0)
	var denom = a * c - b * b
	if abs(denom) < 0.0001:
		return 0.0
	var t = (b * e - c * d) / denom
	return t
