extends Node2D

@onready var collision_polygon = $StaticBody2D/CollisionPolygon2D
@onready var debug_polygon = $Polygon2D

@export var debug_mode = false

func set_points(points: PackedVector2Array) -> void:
	collision_polygon.polygon = points
	if debug_mode:
		debug_polygon.polygon = points
