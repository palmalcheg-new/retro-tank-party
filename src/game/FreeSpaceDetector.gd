extends SGArea2D

var area: SGFixedRect2
var rng

func setup_free_space_detector(_area: SGFixedRect2, dimensions: SGFixedVector2, _rng) -> void:
	area = _area
	rng = _rng
	
	var half_dimensions = dimensions.div(SGFixed.TWO)
	var shape = SGRectangleShape2D.new()
	shape.extents = half_dimensions
	$CollisionShape2D.shape = shape

func detect_free_space() -> SGFixedVector2:
	while true:
		# @todo Should we round this to even pixel values?
		set_global_fixed_position(SGFixed.vector2(
			area.position.x + (rng.randi() % int(area.size.x)),
			area.position.y + (rng.randi() % int(area.size.y))))
		sync_to_physics_engine()
		if get_overlapping_bodies().size() == 0 and get_overlapping_areas().size() == 0:
			break
	
	return get_global_fixed_position()
