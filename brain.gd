extends CharacterBody2D


@onready var animatedSprite = $AnimatedSprite2D

var random = RandomNumberGenerator.new()


func _ready():
	animatedSprite.play("default")


func _physics_process(delta):
	velocity.y += 10

	if is_on_wall():
		velocity.x *= -1
	elif is_on_floor():
		velocity.x = 20

	if move_and_slide():
		velocity.x *= -1
