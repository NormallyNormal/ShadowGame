extends CharacterBody2D

@export var speed := 100.0
@export var jump_velocity := -400
@export var min_jump_velocity := -150.0
@export var gravity := 1200.0
@export var coyote_time := 0.15
@export var ground_accel := 800.0
@export var ground_decel := 1200.0
@export var air_accel := 400.0
@export var air_decel := 200.0

@export var beak: Node2D
@export var eye: Node2D
@export var iris: Node2D

@export var bob_amount := 3.0
@export var bob_speed := 6.0

@onready var legs := $Body/Legs
@onready var head := $Body/Head

@export var max_jump_hold := 0.2
var jump_hold_timer := 0.0
var holding_jump := false

var coyote_timer := 0.0
var facing_right := true

var beak_origin_scale_x: float
var eye_origin_x: float
var iris_origin_x: float

var head_origin: Vector2
var bob_timer := 0.0
var head_thrust_offset := 0.0

func _ready() -> void:
	if beak:
		beak_origin_scale_x = beak.scale.x
	if eye:
		eye_origin_x = eye.position.x
	if iris:
		iris_origin_x = iris.position.x
	if head:
		head_origin = head.position

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()

	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if not on_floor:
		velocity.y += gravity * delta

	if Input.is_action_pressed("move_up") and coyote_timer > 0.0:
		holding_jump = true
		jump_hold_timer += delta
		legs.ray_length = 10.0
	else:
		legs.ray_length = 20.0

	if Input.is_action_just_released("move_up"):
		if holding_jump and coyote_timer > 0.0:
			var t = clampf(jump_hold_timer / max_jump_hold, 0.0, 1.0)
			velocity.y = lerpf(min_jump_velocity, jump_velocity, t)
			coyote_timer = 0.0
		holding_jump = false
		jump_hold_timer = 0.0

	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		legs.bend_direction = -1
		direction -= 1.0
		facing_right = false
	if Input.is_action_pressed("move_right"):
		legs.bend_direction = 1
		direction += 1.0
		facing_right = true

	var target_speed = direction * speed
	var accel: float
	if direction != 0.0:
		accel = ground_accel if on_floor else air_accel
	else:
		accel = ground_decel if on_floor else air_decel
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	if head:
		var moving = abs(velocity.x) > 10.0 and on_floor
		if moving:
			bob_timer += delta * bob_speed
			var bob_y = abs(sin(bob_timer)) * bob_amount
			head.position = head_origin + Vector2(0, -bob_y)
		else:
			bob_timer = 0.0

	var target_sign := 1.0 if facing_right else -1.0
	var lerp_speed := 10.0 * delta
	if beak:
		beak.scale.x = lerp(beak.scale.x, beak_origin_scale_x * target_sign, lerp_speed)
	if eye:
		eye.position.x = lerp(eye.position.x, eye_origin_x * target_sign, lerp_speed)
	if iris:
		iris.position.x = lerp(iris.position.x, iris_origin_x * target_sign, lerp_speed)

	move_and_slide()
