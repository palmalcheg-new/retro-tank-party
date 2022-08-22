extends Control

onready var weapon_label = $HBoxContainer/WeaponLabel
onready var ability_label = $HBoxContainer/AbilityLabel
onready var spectator_controls = $SpectatorControls
onready var spectator_camera_switcher = $SpectatorControls/SpectatorCameraSwitcher

func _ready() -> void:
	ability_label.set_message_translation(false)

func set_weapon_label(text: String) -> void:
	weapon_label.visible = true
	weapon_label.blinking = false
	weapon_label.text = text

func clear_weapon_label() -> void:
	weapon_label.visible = false
	weapon_label.blinking = false

func set_ability_label(text: String, charges: int = 1) -> void:
	ability_label.visible = true
	ability_label.blinking = false
	ability_label.text = tr(text)
	if charges > 1:
		ability_label.text += ' (' + str(charges) + ')'

func clear_ability_label() -> void:
	ability_label.visible = false
	ability_label.blinking = false

func clear_all_labels() -> void:
	clear_weapon_label()
	clear_ability_label()
