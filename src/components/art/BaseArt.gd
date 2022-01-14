extends Reference

const PickupGenericVisual = preload("res://src/objects/pickups/PickupGenericVisual.tscn")
const PickupSpriteVisual = preload("res://src/objects/pickups/PickupSpriteVisual.tscn")

var art_style_resource
var texture_replace_cache := {}

func setup_art(_art_style_resource) -> void:
	art_style_resource = _art_style_resource

func setup_terrain_tiles(terrain_tiles: TileSet) -> void:
	if art_style_resource.texture_base_path != "":
		var texture_path = art_style_resource.texture_base_path + '/terraintiles.png'
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			for tile_id in terrain_tiles.get_tiles_ids():
				terrain_tiles.tile_set_texture(tile_id, texture)

func get_texture(texture_name: String):
	if texture_replace_cache.has(texture_name):
		return texture_replace_cache[texture_name]
	
	if art_style_resource.texture_base_path == "":
		return null
	
	var texture_path: String = art_style_resource.texture_base_path + '/' + texture_name + ".png"
	
	if not ResourceLoader.exists(texture_path):
		texture_replace_cache[texture_name] = null
	else:
		var texture = load(texture_path)
		texture_replace_cache[texture_name] = texture
		return texture

func replace_sprite_texture(texture_name: String, node: Node) -> void:
	var sprite = node.get_node_or_null(@"Sprite")
	if sprite:
		var texture = get_texture(texture_name)
		if texture != null and sprite.texture != texture:
			sprite.texture = texture

func get_texture_name_for_visual(id: String, info: Dictionary = {}) -> String:
	match id:
		'TankBody', 'TankTurret', 'TankBullet':
			return id + str(info['player_index'])
		'Explosion':
			return id + str(info['type'])
		'TreeBig', 'TreeSmall':
			return id + '_' + info['color']
		'Pickup':
			return id + '_' + info['name']
	return id

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	if node == null:
		return null
	
	if art_style_resource.texture_base_path != "":
		var texture_name = get_texture_name_for_visual(id, info)
		
		if id == 'Pickup':
			var texture = get_texture(texture_name)
			if texture:
				node = PickupSpriteVisual.instance()
			else:
				node = PickupGenericVisual.instance()
				return node
		
		replace_sprite_texture(texture_name, node)
	
	return node

func get_tank_color(index: int) -> Color:
	return Color()

func get_team_color(index: int) -> Color:
	return Color()
