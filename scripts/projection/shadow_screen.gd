extends MeshInstance3D

@export var projecting_lights : Array[SpotLight3D]
@export var projecting_meshes : Array[MeshInstance3D]
@export var viewport : SubViewport
@export var screen_shapes : Node2D
@export var player_pos : Node2D

func _physics_process(delta: float) -> void:
	var shape_index = 0
	for projecting_light in projecting_lights:
		for projecting_mesh in projecting_meshes:
			var projection = project(projecting_mesh, projecting_light)
			screen_shapes.set_shape(shape_index, projection)
			
			var screen_pos := get_player_screen_pos()
			projecting_mesh.material_override.set_shader_parameter("screen_center_px", screen_pos)
			
			shape_index += 1

func project(target_mesh: MeshInstance3D, projection_origin: SpotLight3D) -> Array[Vector2]:
	var projected_points: Array[Vector2] = []
	
	var quad_mesh := mesh as QuadMesh
	
	var quad_size := quad_mesh.size
	var projection_point := projection_origin.global_position
	var plane_transform := global_transform
	var plane_origin := plane_transform.origin
	var plane_normal := plane_transform.basis.z.normalized()
	
	var vertices: PackedVector3Array = target_mesh.mesh.get_faces()
	
	for vertex in vertices:
		var global_vertex := target_mesh.global_transform * vertex
		
		var projected_2d: Variant = ProjectionMath.project_point_to_plane(
			global_vertex, 
			projection_point, 
			plane_origin, 
			plane_normal, 
			plane_transform,
			quad_size,
		)
		
		if projected_2d != null:
			projected_points.append(projected_2d)
	
	var hull := ProjectionMath.graham_scan(projected_points)
	
	var trimmed_hull := ProjectionMath.clip_to_spotlight_ellipse(hull, projection_origin, plane_transform, 8)
	
	return ProjectionMath.local_to_viewport(trimmed_hull, quad_size, viewport.size)

func get_player_screen_pos() -> Vector2:
	var quad_mesh := mesh as QuadMesh
	var quad_size := quad_mesh.size
	
	var vp_pos := player_pos.global_position
	var vp_size := Vector2(viewport.size)
	
	var uv := vp_pos / vp_size
	
	var local_3d := Vector3(
		(uv.x - 0.5) * quad_size.x,
		(0.5 - uv.y) * quad_size.y,
		0.0
	)
	
	var world_pos := global_transform * local_3d
	
	var camera := get_viewport().get_camera_3d()
	return camera.unproject_position(world_pos)
