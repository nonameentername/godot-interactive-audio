extends CharacterBody2D


@onready var animatedSprite = $AnimatedSprite2D

var direction = 1

var random = RandomNumberGenerator.new()


func _ready():
	animatedSprite.play("default")


func _physics_process(delta):

	if is_on_floor():
		velocity.x = 20 * direction
		velocity.y = 0
	else:
		velocity.y = 400

	if move_and_slide():
		pass

	if is_on_wall():
		direction *= -1
