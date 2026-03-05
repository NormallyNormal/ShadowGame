extends Node2D

var PROJECTED_SHAPE_SCENE = preload("res://scenes/projected_color.tscn")

var projected_shapes : Array[Node2D]

func clear_shapes() -> void:
	for projected_shape in projected_shapes:
		projected_shape.queue_free()
	projected_shapes.clear()

func add_shape() -> Node2D:
	var projected_shape = PROJECTED_SHAPE_SCENE.instantiate()
	add_child(projected_shape)
	projected_shapes.append(projected_shape)
	return projected_shape

func set_shape(index: int, points: PackedVector2Array, color: Colors.ColorID) -> void:
	while len(projected_shapes) < index + 1:
		add_shape()
	projected_shapes[index].set_points(points)
	projected_shapes[index].color = color
