extends Control

signal battle

func _ready():
	pass

func _on_BattleButton_pressed() -> void:
	emit_signal("battle")
