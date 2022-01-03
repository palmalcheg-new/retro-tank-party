extends Node

var art_style_resource: ArtStyle
var art_style

var terrain_tiles: TileSet

func _ready() -> void:
	terrain_tiles = preload("res://assets/terraintiles.tres")
	load_art_style("res://mods/core/art/classic.tres")

func load_art_style(path: String) -> void:
	art_style_resource = load(path)
	art_style = art_style_resource.art_script.new()
	art_style.setup_art(art_style_resource)
	art_style.setup_terrain_tiles(terrain_tiles)
	
	var cursor_texture: Texture = art_style_resource.cursor_texture
	var hotspot = cursor_texture.get_size() / 2
	Input.set_custom_mouse_cursor(cursor_texture, 0, hotspot)

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	var replacement: Node
	
	if node.has_meta('art_replaced') and node.get_meta('art_replaced').hash() == info.hash():
		replacement = node
	else:
		replacement = art_style.replace_visual(id, node, info)
		
		# Protection for badly behaving art scripts.
		if replacement == null:
			replacement = node
		
		replacement.set_meta('art_replaced', info)
	
	if node != replacement:
		if node.has_method('detach_visual'):
			node.detach_visual()
		
		var parent = node.get_parent()
		if parent:
			var orig_name = node.name
			var orig_index = node.get_index()
			
			parent.remove_child(node)
			node.queue_free()
			
			replacement.name = orig_name
			parent.add_child(replacement)
			parent.move_child(replacement, orig_index)
		
		if replacement.has_method('attach_visual'):
			replacement.attach_visual(info)
	
	if replacement.has_method('start_visual'):
		replacement.start_visual(info)
	
	return replacement

func get_tank_color(index: int) -> Color:
	return art_style.get_tank_color(index)

func get_team_color(index: int) -> Color:
	return art_style.get_team_color(index)
