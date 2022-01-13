extends "res://src/components/art/BaseArt.gd"

const TANK_COLORS := {
	1: Color("43f7ff"),
	2: Color("25ff50"),
	3: Color("f63824"),
	4: Color("f8f8f8"),
}

const TEAM_COLORS := [
	Color('#f63824'),
	Color('#43f7ff'),
]

func get_tank_color(index: int) -> Color:
	return TANK_COLORS[index]

func get_team_color(index: int) -> Color:
	return TEAM_COLORS[index]
