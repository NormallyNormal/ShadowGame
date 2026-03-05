extends Node2D

@onready var collision_polygon = $Area2D/CollisionPolygon2D
@onready var debug_polygon = $Polygon2D

@export var debug_mode = false
@export var color = Colors.ColorID.WHITE

func set_points(points: PackedVector2Array) -> void:
	collision_polygon.polygon = points
	if debug_mode:
		debug_polygon.polygon = points

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("playerbody"):
		Colors.add_source(color, self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("playerbody"):
		Colors.remove_source(color, self)
