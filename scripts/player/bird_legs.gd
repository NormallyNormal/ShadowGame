extends Node2D

@export var grid_snap: float = 15.0
@export var y_offset: float = 0.0
@export var ray_length: float = 20.0
@export var ray_extension: float = 15.0
@export var segment_length: float = 12.0
@export_flags_2d_physics var collision_mask: int = 1
@export_enum("Left:-1", "Right:1") var bend_direction: int = 1
@export var step_duration: float = 0.2
@export var step_height: float = 15.0
@export var step_threshold: float = 2.0
@export var bend_speed: float = 8.0

@export var line_left: Line2D
@export var line_right: Line2D
@export var collider_left: CollisionShape2D
@export var collider_right: CollisionShape2D
@export var head_slip: CollisionPolygon2D

var in_jump

var _left_from: Vector2
var _left_to: Vector2
var _left_current: Vector2
var _left_t: float = 1.0
var _left_bend: float = 1.0

var _right_from: Vector2
var _right_to: Vector2
var _right_current: Vector2
var _right_t: float = 1.0
var _right_bend: float = 1.0

var _initialized: bool = false

func _physics_process(delta: float) -> void:
	var pos = global_position
	var grid_index_floor = int(floor(pos.x / grid_snap))
	var grid_index_ceil = int(ceil(pos.x / grid_snap))
	if grid_index_floor == grid_index_ceil:
		grid_index_ceil += 1
	var even_x: float
	var odd_x: float
	if grid_index_floor % 2 == 0:
		even_x = grid_index_floor * grid_snap
		odd_x = grid_index_ceil * grid_snap
	else:
		odd_x = grid_index_floor * grid_snap
		even_x = grid_index_ceil * grid_snap
	var ray_start_left = Vector2(even_x, pos.y + y_offset)
	var ray_start_right = Vector2(odd_x, pos.y + y_offset)
	var col_hit_left = cast_ray(ray_start_left, ray_start_left + Vector2(0, ray_length))
	var col_hit_right = cast_ray(ray_start_right, ray_start_right + Vector2(0, ray_length))
	var vis_hit_left = cast_ray(ray_start_left, ray_start_left + Vector2(0, ray_length + ray_extension))
	var vis_hit_right = cast_ray(ray_start_right, ray_start_right + Vector2(0, ray_length + ray_extension))

	var no_ground = vis_hit_left == Vector2.INF and vis_hit_right == Vector2.INF
	var airborne = in_jump or no_ground

	if col_hit_left == Vector2.INF:
		col_hit_left = ray_start_left + Vector2(0, ray_length)
	if col_hit_right == Vector2.INF:
		col_hit_right = ray_start_right + Vector2(0, ray_length)

	if airborne:
		var dangle_dist = segment_length * 2.0 - 5.0
		vis_hit_left = pos + Vector2(-2, y_offset + dangle_dist)
		vis_hit_right = pos + Vector2(2, y_offset + dangle_dist)
	else:
		if vis_hit_left == Vector2.INF:
			vis_hit_left = ray_start_left + Vector2(0, ray_length + ray_extension)
		if vis_hit_right == Vector2.INF:
			vis_hit_right = ray_start_right + Vector2(0, ray_length + ray_extension)

	head_slip.position.y = ray_length + 12
	if collider_left:
		var col_target_left = col_hit_left
		collider_left.global_position = collider_left.global_position.lerp(col_target_left, 1.0 - exp(-10.0 * delta))
	if collider_right:
		var col_target_right = col_hit_right
		collider_right.global_position = collider_right.global_position.lerp(col_target_right, 1.0 - exp(-10.0 * delta))
	if not _initialized:
		_left_from = vis_hit_left
		_left_to = vis_hit_left
		_left_current = vis_hit_left
		_right_from = vis_hit_right
		_right_to = vis_hit_right
		_right_current = vis_hit_right
		_left_bend = float(bend_direction)
		_right_bend = float(bend_direction)
		_initialized = true

	if airborne:
		_left_current = _left_current.lerp(vis_hit_left, 1.0 - exp(-20.0 * delta))
		_right_current = _right_current.lerp(vis_hit_right, 1.0 - exp(-20.0 * delta))
		_left_to = vis_hit_left
		_left_from = _left_current
		_left_t = 1.0
		_right_to = vis_hit_right
		_right_from = _right_current
		_right_t = 1.0
	else:
		if vis_hit_left == Vector2.INF:
			vis_hit_left = ray_start_left + Vector2(0, ray_length + ray_extension)
		if vis_hit_right == Vector2.INF:
			vis_hit_right = ray_start_right + Vector2(0, ray_length + ray_extension)
		vis_hit_right -= Vector2(0, 2)
		vis_hit_left -= Vector2(0, 2)

		if vis_hit_left.distance_to(_left_to) > step_threshold:
			_left_from = _left_current
			_left_to = vis_hit_left
			_left_t = 0.0
		elif _left_t >= 1.0:
			_left_to = vis_hit_left
			_left_from = vis_hit_left
			_left_current = vis_hit_left
		if vis_hit_right.distance_to(_right_to) > step_threshold:
			_right_from = _right_current
			_right_to = vis_hit_right
			_right_t = 0.0
		elif _right_t >= 1.0:
			_right_to = vis_hit_right
			_right_from = vis_hit_right
			_right_current = vis_hit_right
		if _left_t < 1.0:
			_left_t = minf(_left_t + delta / step_duration, 1.0)
		if _right_t < 1.0:
			_right_t = minf(_right_t + delta / step_duration, 1.0)
		_left_current = _arc_lerp(_left_from, _left_to, _left_t)
		_right_current = _arc_lerp(_right_from, _right_to, _right_t)

		var ground_at_left = cast_ray(_left_current - Vector2(0, ray_length), _left_current + Vector2(0, 5))
		if ground_at_left != Vector2.INF and _left_current.y > ground_at_left.y:
			_left_current = ground_at_left
			_left_from = ground_at_left
			_left_to = vis_hit_left
			_left_t = 1.0

		var ground_at_right = cast_ray(_right_current - Vector2(0, ray_length), _right_current + Vector2(0, 5))
		if ground_at_right != Vector2.INF and _right_current.y > ground_at_right.y:
			_right_current = ground_at_right
			_right_from = ground_at_right
			_right_to = vis_hit_right
			_right_t = 1.0
	if line_left:
		var desired_left = _desired_bend(line_left, _left_current)
		_left_bend = lerp(_left_bend, desired_left, 1.0 - exp(-bend_speed * delta))
		solve_ik(line_left, _left_current, _left_bend, not airborne)
	if line_right:
		var desired_right = _desired_bend(line_right, _right_current)
		_right_bend = lerp(_right_bend, desired_right, 1.0 - exp(-bend_speed * delta))
		solve_ik(line_right, _right_current, _right_bend, not airborne)


func _desired_bend(line: Line2D, target: Vector2) -> float:
	return float(bend_direction)


func _arc_lerp(from: Vector2, to: Vector2, t: float) -> Vector2:
	var smooth_t = t * t * (3.0 - 2.0 * t)
	var pos_out = from.lerp(to, smooth_t)
	var step_dist = from.distance_to(to)
	var horizontal_ratio = clampf(abs(to.x - from.x) / maxf(step_dist, 0.01), 0.0, 1.0)
	var arc = 4.0 * t * (1.0 - t) * step_height * horizontal_ratio
	var lerp_y_delta = (to.y - from.y) * smooth_t
	var net_lift = maxf(arc - maxf(lerp_y_delta, 0.0), 0.0)
	pos_out.y -= net_lift
	return pos_out


func cast_ray(from: Vector2, to: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	var body = get_parent().get_parent()
	if body is PhysicsBody2D:
		query.exclude = [body.get_rid()]
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector2.INF


@export var max_stretch: float = 1.5

func solve_ik(line: Line2D, target: Vector2, smooth_bend: float, allow_stretch: bool = true) -> void:
	while line.get_point_count() < 3:
		line.add_point(Vector2.ZERO)
	var start = line.global_transform * line.get_point_position(0)
	var to_target = target - start
	var dist = to_target.length()
	var max_reach = segment_length * 2.0
	var seg = segment_length
	if dist > max_reach:
		if allow_stretch:
			var max_seg = segment_length * max_stretch
			seg = minf(dist / 2.0, max_seg)
			var clamped_reach = seg * 2.0
			if dist > clamped_reach:
				target = start + to_target.normalized() * clamped_reach
				dist = clamped_reach
		else:
			target = start + to_target.normalized() * max_reach
			dist = max_reach
	if dist < 0.01:
		dist = 0.01
	var a = seg
	var b = seg
	var cos_angle = clampf((a * a + dist * dist - b * b) / (2.0 * a * dist), -1.0, 1.0)
	var angle_to_target = to_target.angle()
	var elbow_offset_angle = acos(cos_angle)
	var elbow_pos = start + Vector2(cos(angle_to_target + elbow_offset_angle), sin(angle_to_target + elbow_offset_angle)) * a
	var elbow_neg = start + Vector2(cos(angle_to_target - elbow_offset_angle), sin(angle_to_target - elbow_offset_angle)) * a
	var blend = (smooth_bend + 1.0) * 0.5
	var elbow = elbow_neg.lerp(elbow_pos, blend)
	line.set_point_position(1, line.to_local(elbow))
	line.set_point_position(2, line.to_local(target))
