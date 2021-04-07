extends Node2D

func map_start() -> void:
	get_tree().call_group("map_object", "map_object_start")

func map_stop() -> void:
	get_tree().call_group("map_object", "map_object_stop")

func get_map_rect() -> Rect2:
	if not has_node("TileMap"):
		return Rect2()
	
	var tilemap = $TileMap
	var tilemap_rect = tilemap.get_used_rect()
	
	if tilemap_rect.size.x > 0 and tilemap_rect.size.y > 0:
		# Leave a margin of 1 tile all the way around the map to account for camera
		# shake, so remove those from the rect.
		tilemap_rect.position += Vector2(1.0, 1.0)
		tilemap_rect.size -= Vector2(2.0, 2.0)
	
	# Convert tile space to pixel space
	tilemap_rect.position = (tilemap_rect.position * tilemap.cell_size) + tilemap.global_position
	tilemap_rect.size *= tilemap.cell_size

	return tilemap_rect
