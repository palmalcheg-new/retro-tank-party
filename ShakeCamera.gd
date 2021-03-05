extends Camera2D

export var decay: float = 0.8
export var max_offset := Vector2(100, 75)
export var max_roll: float = 0.1

var trauma: float = 0.0
var trauma_power: int = 2

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	#else:
	#	rotation = 0.0

func shake() -> void:
	var amount: float = pow(trauma, trauma_power)
	rotation = max_roll * amount * rand_range(-1, 1)
	offset.x = max_offset.x * amount * rand_range(-1, 1)
	offset.y = max_offset.y * amount * rand_range(-1, 1)
