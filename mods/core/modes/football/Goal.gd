extends SGArea2D

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
onready var collision_shape: SGCollisionShape2D = $CollisionShape2D
onready var goal_horn: AudioStreamPlayer = $GoalHorn

export (GoalColor) var goal_color: int = GoalColor.RED setget set_goal_color

signal tank_present (tank, area)

func set_goal_color(_goal_color: int) -> void:
	if goal_color != _goal_color:
		goal_color = _goal_color
		if not sprite:
			yield(self, "ready")
		sprite.texture = sprites[_goal_color]

func _network_process(delta: float, input: Dictionary) -> void:
	check_for_tanks()

func check_for_tanks() -> void:
	for body in get_overlapping_bodies():
		emit_signal("tank_present", body, self)

func celebrate() -> void:
	goal_horn.play()
	for i in range(6):
		get_tree().create_timer(randf()).connect("timeout", self, "_launch_fireworks")

func _launch_fireworks() -> void:
	var shape_float_extents = collision_shape.shape.extents.to_float()
	var top_left = collision_shape.global_position - shape_float_extents
	
	var fireworks = Fireworks.instance()
	get_tree().get_root().add_child(fireworks)
	fireworks.global_position = Vector2(
		top_left.x + (randi() % int(shape_float_extents.x * 2)),
		top_left.y + (randi() % int(shape_float_extents.y * 2)))
	fireworks.color = Globals.art.get_team_color(goal_color)

