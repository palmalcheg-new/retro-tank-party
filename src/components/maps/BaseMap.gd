extends Node2D

var _map_rect

const ONE_NINETY_SIX = 196 * SGFixed.ONE

func map_start(game) -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "map_object", "map_object_start", self, game)

func map_stop(game) -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "map_object", "map_object_stop", self, game)

func get_map_rect() -> Rect2:
	if _map_rect != null:
		return _map_rect
	
	var tilemap = get_node_or_null(@"TileMap")
	if not tilemap:
		_map_rect = Rect2()
		return _map_rect
	
	_map_rect = tilemap.get_used_rect()
	if _map_rect.size.x > 0 and _map_rect.size.y > 0:
		# Leave a margin of 1 tile all the way around the map to account for camera
		# shake, so remove those from the rect.
		_map_rect.position += Vector2(1.0, 1.0)
		_map_rect.size -= Vector2(2.0, 2.0)
	
	# Convert tile space to pixel space
	_map_rect.position = (_map_rect.position * tilemap.cell_size) + tilemap.global_position
	_map_rect.size *= tilemap.cell_size
	
	return _map_rect

func get_map_fixed_rect() -> SGFixedRect2:
	# It *should* be OK to convert from floats here because the values are
	# actually all integers, and floats should have full precision at the
	# sort of values we're using here.
	return SGFixed.from_float_rect2(get_map_rect())

func _get_child_transforms(parent: Node2D) -> Array:
	var transforms := []
	for i in range(parent.get_child_count()):
		transforms.append(parent.get_child(i).get_global_fixed_transform())
	return transforms

func get_player_start_transforms() -> Array:
	var player_start_positions = get_node_or_null(@"PlayerStartPositions")
	if not player_start_positions:
		return []
	return _get_child_transforms(player_start_positions)

func get_ball_start_position() -> SGFixedVector2:
	var ball_start_position = get_node_or_null(@"BallStartPosition")
	if not ball_start_position:
		var map_rect = get_map_rect()
		return SGFixed.from_float_vector2(map_rect.position + (map_rect.size / 2))
		
	return ball_start_position.get_global_fixed_position()

func get_team_start_transforms(team: int) -> Array:
	var team_start_positions_parent = get_node_or_null(@"TeamStartPositions")
	if not team_start_positions_parent:
		return []
	if team >= team_start_positions_parent.get_child_count():
		return []
	return _get_child_transforms(team_start_positions_parent.get_child(team))

func get_goal_transforms() -> Array:
	var goal_positions_parent: Node2D = get_node_or_null(@"GoalPositions")
	
	var goal_transforms := []
	var fixed_map_rect = get_map_fixed_rect()
	
	for i in range(2):
		if goal_positions_parent and goal_positions_parent.get_child_count() > i:
			var goal_position_node: SGFixedNode2D = goal_positions_parent.get_child(i)
			goal_transforms.append(goal_position_node.get_global_fixed_transform())
		else:
			if i == 0:
				goal_transforms.append(SGFixed.transform2d(0, fixed_map_rect.position.add(SGFixed.vector2(ONE_NINETY_SIX, fixed_map_rect.size.y / 2))))
			else:
				goal_transforms.append(SGFixed.transform2d(SGFixed.PI, fixed_map_rect.position.add(SGFixed.vector2(fixed_map_rect.size.x - ONE_NINETY_SIX, fixed_map_rect.size.y / 2))))
	
	return goal_transforms
