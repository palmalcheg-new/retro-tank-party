extends Control

onready var weapon_label = $HBoxContainer/WeaponLabel
onready var ability_label = $HBoxContainer/AbilityLabel

func set_weapon_label(text: String) -> void:
	weapon_label.visible = true
	weapon_label.text = text

func clear_weapon_label() -> void:
	weapon_label.visible = false

func set_ability_label(text: String, charges: int = 1) -> void:
	ability_label.visible = true
	ability_label.text = text
	if charges > 1:
		ability_label.text += ' (' + str(charges) + ')'

func clear_ability_label():
	ability_label.visible = false
