extends CharacterBody2D
class_name Player


@export var high_jump_height: float
@export var jump_height: float
@export var jump_time_to_peak: float
@export var jump_time_to_descent: float
@export var walk_speed = 300.0
@export var run_speed = 600.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var shoot_timer: Timer = $Timer

var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

var flipped = false
var walking = false
var ducking = false
var jumping = false
var shooting = false
var shooting_held = false

var bullet_scene: PackedScene


enum PlayerState { IDLE, WALKING, RUNNING, JUMPING, HIGH_JUMP, DUCKING }


var previous_state: PlayerState
var current_state: PlayerState = PlayerState.IDLE


signal brain_collision
signal jump
signal shoot


func _ready():
	bullet_scene = preload("res://bullet.tscn")

	animated_sprite.play("idle")
	shoot_timer.timeout.connect(_on_shoot_timer)


func _on_shoot_timer():
	shooting = false


func get_my_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity


func set_current_state(state: PlayerState):
	if current_state != state:
		previous_state = current_state
		current_state = state


func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")

	if Input.is_action_just_pressed("shoot"):
		shooting_held = true

		shoot.emit()

		shooting = true
		shoot_timer.start()

		var bullet: Bullet = bullet_scene.instantiate()
		bullet.flipped = flipped

		if input_direction.y > 0:
			bullet.position = global_position + Vector2(0, 12)
		else:
			bullet.position = global_position + Vector2(0, -8)

		get_parent().add_child(bullet)
		
		if jumping:
			animated_sprite.play("jump_shoot")
		elif input_direction.y > 0:
			animated_sprite.play("duck_shoot")
		else:
			animated_sprite.play("shoot")

	if Input.is_action_just_released("shoot"):
		shooting_held = false

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			jump.emit()
			animated_sprite.play("start_jump")
			velocity.y = jump_velocity
			if shooting_held:
				set_current_state(PlayerState.HIGH_JUMP)
			else:
				set_current_state(PlayerState.JUMPING)
	elif jumping:
		if not shooting:
			animated_sprite.play("jump")

	if Input.is_action_just_released("jump"):
		if velocity.y < 0:
			velocity.y = 0

	jumping = not is_on_floor()


	var velocity_x

	if current_state == PlayerState.RUNNING or current_state == PlayerState.HIGH_JUMP:
		jump_velocity = ((2.0 * high_jump_height) / jump_time_to_peak) * -1.0
		jump_gravity = ((-2.0 * high_jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
		fall_gravity = ((-2.0 * high_jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

		velocity_x = input_direction.x * run_speed
	else:
		jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
		jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
		fall_gravity = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

		if not shooting:
			velocity_x = input_direction.x * walk_speed
		else:
			velocity_x = 0

	if velocity_x < 0 and not flipped:
		animated_sprite.flip_h = true
		flipped = true

	if velocity_x > 0 and flipped:
		animated_sprite.flip_h = false
		flipped = false

	if input_direction.y > 0 and not jumping:
		if not shooting:
			animated_sprite.play("duck")
		ducking = true
		set_current_state(PlayerState.DUCKING)
	else:
		ducking = false

	if not ducking:
		if abs(velocity_x) > 0:
			if not walking:
				animated_sprite.play("start_walk")
				walking = true
				if shooting_held:
					set_current_state(PlayerState.RUNNING)
				else:
					set_current_state(PlayerState.WALKING)
			else:
				if jumping:
					#set_current_state(PlayerState.JUMPING)
					if not shooting:
						animated_sprite.play("jump")
				else:
					if shooting_held:
						set_current_state(PlayerState.RUNNING)
					else:
						set_current_state(PlayerState.WALKING)

					animated_sprite.play("walk")
		else:
			if jumping and not shooting:
				#set_current_state(PlayerState.JUMPING)
				animated_sprite.play("jump")
			else:
				set_current_state(PlayerState.IDLE)

				if not shooting:
					animated_sprite.play("idle")
			walking = false

		if velocity_x == 0 and not jumping:
			set_current_state(PlayerState.IDLE)

		velocity.x = velocity_x
	else:
		velocity.x = 0
		#current_state = PlayerState.IDLE

	velocity.y += get_my_gravity() * delta

	move_and_slide()
	handle_collisions()


func handle_collisions():
	for index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var _collider = collision.get_collider()
		if collision.get_collider() is Brain:
			brain_collision.emit()
