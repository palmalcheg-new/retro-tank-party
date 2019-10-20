extends Control

signal battle
signal practice

func _ready():
	pass

func _on_BattleButton_pressed() -> void:
	emit_signal("battle")
func _on_PracticeButton_pressed() -> void:
	emit_signal("practice")
