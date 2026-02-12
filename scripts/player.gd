extends CharacterBody2D

@export var speed := 100.0
@export var jump_velocity := -400.0
@export var gravity := 1000.0
@export var coyote_time := 0.15

var coyote_timer := 0.0

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("move_up") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0
		
	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	
	velocity.x = direction * speed
	
	move_and_slide()
