extends "res://src/components/art/BaseArt.gd"

const TANK_COLORS := {
	1: Color("419fdd"),
	2: Color("2ecc71"),
	3: Color("e74c3c"),
	4: Color("5f5d55"),
}

const TEAM_COLORS := [
	Color('#e74c3c'),
	Color('#419fdd'),
]

func get_tank_color(index: int) -> Color:
	return TANK_COLORS[index]

func get_team_color(index: int) -> Color:
	return TEAM_COLORS[index]

func get_texture_name_for_visual(id: String, info: Dictionary = {}) -> String:
	match id:
		'TreeBig', 'TreeSmall':
			return id
	return .get_texture_name_for_visual(id, info)
