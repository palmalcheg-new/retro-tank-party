extends ColorRect

onready var entity_name_label = $VBoxContainer/NameLabel
onready var score_label = $VBoxContainer/ScoreLabel

func set_entity_name(name: String) -> void:
	entity_name_label.text = name

func set_score(score: int) -> void:
	score_label.text = str(score)
