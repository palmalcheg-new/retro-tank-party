extends ColorRect

onready var player_name_label = $VBoxContainer/PlayerNameLabel
onready var score_label = $VBoxContainer/ScoreLabel

func set_player_name(name: String) -> void:
	player_name_label.text = name

func set_score(score: int) -> void:
	score_label.text = str(score)
