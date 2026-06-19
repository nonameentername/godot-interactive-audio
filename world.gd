extends Node2D

var random = RandomNumberGenerator.new()

@export
var brain_scene: PackedScene

@onready
var timer: Timer = $Timer

@onready
var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

func _ready():
	timer.start()


func _on_timer_timeout() -> void:
	spawn_location.progress_ratio = random.randf()
	
	var brain: Node2D = brain_scene.instantiate()
	
	add_child(brain)
	move_child(brain, 7)

	brain.global_position = spawn_location.global_position
