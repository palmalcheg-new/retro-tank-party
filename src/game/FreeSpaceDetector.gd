extends Area2D

var detection_area: Rect2
var detecting := false
var wait_frames: int

signal free_space_found (position)

func start_detecting(_detection_area: Rect2, dimensions: Vector2) -> void:
	var half_dimensions = dimensions / 2.0
	
	var shape = RectangleShape2D.new()
	shape.extents = half_dimensions
	$CollisionShape2D.shape = shape
	
	detection_area = _detection_area
	detection_area.position += half_dimensions
	detection_area.size -= half_dimensions
	
	try_next_position()
	
	detecting = true

func try_next_position() -> void:
	position = Vector2(
		detection_area.position.x + (randi() % int(detection_area.size.x)),
		detection_area.position.y + (randi() % int(detection_area.size.y)))
	wait_frames = 1

func _physics_process(delta: float) -> void:
	if detecting:
		if wait_frames > 0:
			wait_frames -= 1
			return
		if get_overlapping_bodies().size() > 0 or get_overlapping_areas().size() > 0:
			try_next_position()
			return
		
		emit_signal("free_space_found", position)
		detecting = false
