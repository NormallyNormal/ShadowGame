extends Node3D

@export var rate := 1.0

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		rotation.y += delta * rate
	if Input.is_action_pressed("ui_right"):
		rotation.y -= delta * rate
	if Input.is_action_pressed("ui_up"):
		rotation.x += delta * rate
	if Input.is_action_pressed("ui_down"):
		rotation.x -= delta * rate
