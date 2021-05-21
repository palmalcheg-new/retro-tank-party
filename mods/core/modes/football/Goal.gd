extends Area2D

const RedSprite = preload("res://mods/core/modes/football/goal_red.png")
const BlueSprite = preload("res://mods/core/modes/football/goal_blue.png")

const sprites := [
	RedSprite,
	BlueSprite,
]

enum GoalColor {
	RED,
	BLUE,
}

onready var sprite: Sprite = $Sprite

export (GoalColor) var goal_color: int = GoalColor.RED setget set_goal_color

signal tank_present (tank, area)

func set_goal_color(_goal_color: int) -> void:
	if goal_color != _goal_color:
		goal_color = _goal_color
		if not sprite:
			yield(self, "ready")
		sprite.texture = sprites[_goal_color]

func check_for_tanks() -> void:
	for body in get_overlapping_bodies():
		emit_signal("tank_present", body, self)

func _on_Goal_body_entered(body: Node) -> void:
	emit_signal("tank_present", body, self)
