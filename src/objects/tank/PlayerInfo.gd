extends Node2D

onready var health_node := $Health
onready var player_name_label := $PlayerName

var health_bar_max: int

func _ready() -> void:
	health_bar_max = health_node.rect_size.x

func update_health(_health: int) -> void:
	health_node.rect_size.x = (float(_health) / 100) * health_bar_max

func set_player_name(_name: String) -> void:
	player_name_label.text = _name

func set_team_color(color: Color) -> void:
	player_name_label.add_color_override("font_color", color)
