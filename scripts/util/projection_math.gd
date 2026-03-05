extends Node

func project_point_to_plane(point: Vector3, projection_point: Vector3, plane_origin: Vector3, plane_normal: Vector3, plane_transform: Transform3D, quad_size: Vector2) -> Variant:
	var ray_direction := (point - projection_point).normalized()
	var denom := plane_normal.dot(ray_direction)
	if abs(denom) < 0.0001:
		return null
	
	var t := plane_normal.dot(plane_origin - projection_point) / denom
	if t < 0:
		return null
		
	var intersection := projection_point + ray_direction * t
	var local_point := plane_transform.affine_inverse() * intersection
	
	return Vector2(local_point.x, local_point.y)


func graham_scan(points: Array[Vector2]) -> Array[Vector2]:
	if points.size() < 3:
		return points
	
	var lowest_idx := 0
	for i in range(1, points.size()):
		if points[i].y < points[lowest_idx].y:
			lowest_idx = i
		elif points[i].y == points[lowest_idx].y and points[i].x < points[lowest_idx].x:
			lowest_idx = i
	
	var pivot := points[lowest_idx]
	
	var sorted_points: Array[Vector2] = []
	for i in range(points.size()):
		if i != lowest_idx:
			sorted_points.append(points[i])
	
	sorted_points.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var cross := cross_product(pivot, a, b)
		if abs(cross) < 0.0001:
			var dist_a := pivot.distance_squared_to(a)
			var dist_b := pivot.distance_squared_to(b)
			return dist_a < dist_b
		return cross > 0
	)
	
	var filtered: Array[Vector2] = []
	for i in range(sorted_points.size()):
		while filtered.size() > 0 and abs(cross_product(pivot, filtered.back(), sorted_points[i])) < 0.0001:
			filtered.pop_back()
		filtered.append(sorted_points[i])
	
	if filtered.size() < 2:
		var result: Array[Vector2] = [pivot]
		result.append_array(filtered)
		return result
	
	var hull: Array[Vector2] = [pivot, filtered[0], filtered[1]]
	
	for i in range(2, filtered.size()):
		while hull.size() > 1 and cross_product(hull[-2], hull[-1], filtered[i]) <= 0:
			hull.pop_back()
		hull.append(filtered[i])
	
	return hull


func cross_product(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)

func clip_to_spotlight_ellipse(
	points: Array[Vector2],
	projection_origin: SpotLight3D,
	plane_transform: Transform3D,
	arc_segments: int = 8,
	debug: bool = false
) -> Array[Vector2]:
	var ellipse_points: Variant = _compute_spotlight_ellipse(
		projection_origin,
		plane_transform,
		32
	)
	
	if ellipse_points == null:
		return []
	
	if debug:
		return ellipse_points
	
	return _clip_polygon_to_polygon(points, ellipse_points)

func get_spotlight_ellipse(projection_origin: SpotLight3D, plane_transform: Transform3D) -> Array[Vector2]:
	return _compute_spotlight_ellipse(
		projection_origin,
		plane_transform,
		32
	)

func _clip_polygon_to_polygon(
	subject: Array[Vector2],
	clip: Array[Vector2]
) -> Array[Vector2]:
	if clip.size() < 3:
		return []
	
	var output: Array[Vector2] = subject.duplicate()
	
	var clip_size := clip.size()
	
	for i in range(clip_size):
		if output.size() == 0:
			break
		
		var input: Array[Vector2] = output.duplicate()
		output.clear()
		
		var edge_start := clip[i]
		var edge_end := clip[(i + 1) % clip_size]
		
		for j in range(input.size()):
			var curr := input[j]
			var next := input[(j + 1) % input.size()]
			
			var curr_inside := _is_left_of_line(curr, edge_start, edge_end)
			var next_inside := _is_left_of_line(next, edge_start, edge_end)
			
			if curr_inside:
				output.append(curr)
				if not next_inside:
					var intersect : Variant = _line_intersection(curr, next, edge_start, edge_end)
					if intersect != null:
						output.append(intersect)
			else:
				if next_inside:
					var intersect : Variant = _line_intersection(curr, next, edge_start, edge_end)
					if intersect != null:
						output.append(intersect)
	
	return output

func _is_left_of_line(point: Vector2, a: Vector2, b: Vector2) -> bool:
	return cross_product(a, b, point) <= 0


func _line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> Variant:
	var d1 := p2 - p1
	var d2 := p4 - p3
	
	var cross := d1.x * d2.y - d1.y * d2.x
	
	if abs(cross) < 1e-10:
		return null
	
	var d3 := p3 - p1
	var t := (d3.x * d2.y - d3.y * d2.x) / cross
	
	if t < 0.0 or t > 1.0:
		return null
	
	return p1 + d1 * t

func _compute_spotlight_ellipse(
	spotlight: SpotLight3D,
	plane_transform: Transform3D,
	num_segments: int = 64
) -> Variant:
	var light_pos := spotlight.global_position
	var light_dir := -spotlight.global_transform.basis.z.normalized()
	var spot_angle := deg_to_rad(spotlight.spot_angle)
	var spot_range := spotlight.spot_range
	
	var plane_origin := plane_transform.origin
	var plane_normal := plane_transform.basis.z.normalized()
	
	var to_light := light_pos - plane_origin
	var signed_dist := to_light.dot(plane_normal)
	
	if signed_dist <= 0:
		return null
	
	var axis_dot_normal := light_dir.dot(plane_normal)
	
	if axis_dot_normal >= -0.0001:
		return null
	
	var perp := (plane_normal - light_dir * axis_dot_normal).normalized()
	var perp2 := light_dir.cross(perp).normalized()
	
	var ellipse_points_2d: Array[Vector2] = []
	
	for i in range(num_segments):
		var angle := TAU * float(i) / float(num_segments)
		
		var cone_dir := (
			light_dir * cos(spot_angle) +
			(perp * cos(angle) + perp2 * sin(angle)) * sin(spot_angle)
		).normalized()
		
		var denom := cone_dir.dot(plane_normal)
		if abs(denom) < 0.0001:
			continue
		
		var t := -signed_dist / denom
		if t <= 0 or t > spot_range:
			continue
		
		var point := light_pos + cone_dir * t
		var local := plane_transform.affine_inverse() * point
		ellipse_points_2d.append(Vector2(local.x, local.y))
	
	if ellipse_points_2d.size() < 3:
		return null
	
	return ellipse_points_2d

func local_to_viewport(
	points: Array[Vector2],
	quad_size: Vector2,
	viewport_size: Vector2
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.resize(points.size())
	
	for i in range(points.size()):
		var local := points[i]
		
		var uv := Vector2(
			(local.x / quad_size.x) + 0.5,
			(-local.y / quad_size.y) + 0.5
		)
		
		result[i] = Vector2(
			uv.x * viewport_size.x,
			uv.y * viewport_size.y
		)
	
	return result
