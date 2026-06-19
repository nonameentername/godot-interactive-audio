extends Camera2D

@export var min_x: int = 0
@export var max_x: int = 4368
@export var min_y: int = 0
@export var max_y: int = 1000

func _process(delta: float) -> void:
	limit_left = min_x
	limit_right = max_x
	limit_top = min_y
	limit_bottom = max_y
