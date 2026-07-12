extends RigidBody2D
class_name Bullet

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var timer: Timer = $Timer

@export
var flipped = false

var velocity: Vector2


func _ready() -> void:
	animated_sprite.play("start")
	timer.timeout.connect(_on_timeout)

	animated_sprite.flip_h = not flipped

	velocity.x = 800

	if flipped:
		velocity.x *= -1
	else:
		collision_shape.position *= -1


func _on_timeout():
	animated_sprite.play("default")


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		animated_sprite.play("end")

		if collision.get_collider() is Brain:
			await get_tree().create_timer(0.2).timeout
			queue_free()

			if not collision.get_collider().is_queued_for_deletion():
				collision.get_collider().free()
		else:
			await get_tree().create_timer(1.0).timeout
			queue_free()

