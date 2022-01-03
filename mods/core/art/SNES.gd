extends "res://src/components/art/BaseArt.gd"

const TankBodyVisual = preload("res://mods/core/art/snes/TankBodyVisual.tscn")

const TANK_COLORS := {
	1: Color("25d9d3"),
	2: Color("9ad72e"),
	3: Color("e41a3c"),
	4: Color("bbc2cd"),
}

const TEAM_COLORS := [
	Color('e41a3c'),
	Color('25d9d3'),
]

func get_tank_color(index: int) -> Color:
	return TANK_COLORS[index]

func get_team_color(index: int) -> Color:
	return TEAM_COLORS[index]

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	if id == 'TankBody':
		var visual = TankBodyVisual.instance()
		replace_sprite_texture(get_texture_name_for_visual(id, info), visual)
		return visual
	
	return .replace_visual(id, node, info)
