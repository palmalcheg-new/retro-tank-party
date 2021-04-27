extends Node2D

onready var health_node := $Background/VBoxContainer/Health
onready var player_name_label := $Background/VBoxContainer/HBoxContainer/PlayerName
onready var team_parent := $Background/VBoxContainer/HBoxContainer/Team
onready var team_label := $Background/VBoxContainer/HBoxContainer/Team/Label

var health_bar_max: int

func _ready() -> void:
	health_bar_max = health_node.rect_size.x

func update_health(_health: int) -> void:
	health_node.rect_size.x = (float(_health) / 100) * health_bar_max

func set_player_name(_name: String) -> void:
	player_name_label.text = _name

func set_team(team: int) -> void:
	team_parent.visible = true
	team_parent.color = Globals.TEAM_COLORS[team]
	team_label.text = Globals.TEAM_NAMES[team][0]
