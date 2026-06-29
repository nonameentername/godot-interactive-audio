extends CharacterBody2D
class_name Brain


@onready var animatedSprite = $AnimatedSprite2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction = 1

var random = RandomNumberGenerator.new()


func _ready():
	animatedSprite.play("default")


func _physics_process(delta):
	collision_shape.shape.size = Vector2(32, 16)

	if is_on_floor():
		velocity.x = 20 * direction
		velocity.y = 0
	else:
		velocity.y = 400

	if move_and_slide():
		pass

	if is_on_wall():
		handle_collisions()


func handle_collisions():
	for index in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var _collider = collision.get_collider()
		if collision.get_collider() is Player:
			collision_shape.shape.size = Vector2(64, 16)
		else:
			direction *= -1
