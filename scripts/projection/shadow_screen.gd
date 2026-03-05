extends MeshInstance3D

var projecting_lights : Array[SpotLight3D]
var projecting_meshes : Array[MeshInstance3D]
@export var dithering_meshes : Array[MeshInstance3D]
@export var viewport : SubViewport
@export var screen_shapes : Node2D
@export var screen_colors : Node2D
@export var player_pos : Node2D

func _ready():
	_find_dithering_meshes(get_tree().root)

func _find_dithering_meshes(node: Node):
	if node is MeshInstance3D:
		var mat = node.material_override
		if mat is ShaderMaterial and mat.shader != null:
			if mat.shader.resource_path.ends_with("dithering_material.gdshader"):
				dithering_meshes.append(node)
	for child in node.get_children():
		_find_dithering_meshes(child)

func _physics_process(delta: float) -> void:
	var shape_index = 0
	var color_index = 0
	for projecting_light in projecting_lights:
		if projecting_light.color != Colors.ColorID.WHITE:
			var projection = project_light(projecting_light)
			screen_colors.set_shape(color_index, projection, projecting_light.color)
			color_index += 1
		for projecting_mesh in projecting_meshes:
			var projection = project(projecting_mesh, projecting_light)
			screen_shapes.set_shape(shape_index, projection)
			shape_index += 1
	var screen_pos := get_player_screen_pos()
	for dithering_mesh in dithering_meshes:
		dithering_mesh.material_override.set_shader_parameter("screen_center_px", screen_pos)

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

func project_light(projection_origin: SpotLight3D) -> Array[Vector2]:
	var projected_points: Array[Vector2] = []
	var quad_mesh := mesh as QuadMesh
	var quad_size := quad_mesh.size
	var projection_point := projection_origin.global_position
	var plane_transform := global_transform
	var plane_origin := plane_transform.origin
	var plane_normal := plane_transform.basis.z.normalized()
	projected_points = ProjectionMath.get_spotlight_ellipse(projection_origin, plane_transform)
	return ProjectionMath.local_to_viewport(projected_points, quad_size, viewport.size)

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
