extends Area2D

const RedSprite = preload("res://mods/core/modes/football/goal_red.png")
const BlueSprite = preload("res://mods/core/modes/football/goal_blue.png")
const Fireworks = preload("res://mods/core/modes/football/Fireworks.tscn")

const sprites := [
	RedSprite,
	BlueSprite,
]

enum GoalColor {
	RED,
	BLUE,
}

onready var sprite: Sprite = $Sprite
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var goal_horn: AudioStreamPlayer = $GoalHorn

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

remotesync func celebrate() -> void:
	goal_horn.play()
	for i in range(6):
		get_tree().create_timer(randf()).connect("timeout", self, "_launch_fireworks")

func _launch_fireworks() -> void:
	var top_left = collision_shape.global_position - collision_shape.shape.extents
	
	var fireworks = Fireworks.instance()
	get_tree().get_root().add_child(fireworks)
	fireworks.global_position = Vector2(
		top_left.x + (randi() % int(collision_shape.shape.extents.x * 2)),
		top_left.y + (randi() % int(collision_shape.shape.extents.y * 2)))
	fireworks.color = Globals.TEAM_COLORS[Globals.Teams.RED if goal_color == GoalColor.BLUE else Globals.Teams.BLUE]

