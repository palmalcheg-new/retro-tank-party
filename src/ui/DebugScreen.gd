extends "res://src/ui/Screen.gd"

onready var scroll_container := $Panel/VBoxContainer/ScrollContainer
onready var field_container := $Panel/VBoxContainer/ScrollContainer/GridContainer
onready var health_slider := $Panel/VBoxContainer/ScrollContainer/GridContainer/HealthSlider
onready var invincible_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/InvincibleOptions
onready var weapon_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/WeaponOptions
onready var ability_field := $Panel/VBoxContainer/ScrollContainer/GridContainer/AbilityOptions

var tank
var _is_ready := false

func _ready() -> void:
	invincible_field.add_item("No", false)
	invincible_field.add_item("Yes", true)
	
	var weapons = Modding.find_resources("weapons")
	for weapon_path in weapons:
		var weapon = load(weapon_path)
		weapon_field.add_item(weapon.name, weapon)
	
	ability_field.add_item("None", null)
	var abilities = Modding.find_resources("abilities")
	for ability_path in abilities:
		var ability = load(ability_path)
		ability_field.add_item(ability.name, ability)
	
	_setup_field_neighbors()
	
	_is_ready = true

func _setup_field_neighbors() -> void:
	var previous_neighbor = null;
	for child in field_container.get_children():
		if previous_neighbor:
			previous_neighbor.focus_neighbour_bottom = child.get_path()
			previous_neighbor.focus_next = child.get_path()
			child.focus_neighbour_top = previous_neighbor.get_path()
			child.focus_previous = previous_neighbor.get_path()
		previous_neighbor = child

func _show_screen(info: Dictionary = {}) -> void:
	scroll_container.scroll_vertical = 0
	health_slider.focus.grab_without_sound()
	ui_layer.show_back_button()
	
	tank = info['tank']
	assert (tank)
	if not tank:
		return
	
	health_slider.value = tank.health
	invincible_field.set_value(tank.invincible, false)
	weapon_field.set_value(tank.weapon_type, false)
	ability_field.set_value(tank.ability_type, false)

func _on_HealthSlider_value_changed(value: float) -> void:
	if _is_ready:
		Sounds.play("Select")
	
	if tank:
		tank.update_health(value)

func _on_InvincibleOptions_item_selected(value, index) -> void:
	if tank:
		tank.invincible = value

func _on_WeaponOptions_item_selected(value, index) -> void:
	if tank:
		tank.set_weapon_type(value)

func _on_AbilityOptions_item_selected(value, index) -> void:
	if tank:
		# For 'None', since we can't have a value null in OptionSwitcher.
		if index == 0:
			value = null
		if tank.ability_type != value:
			tank.set_ability_type(value)

func _on_DoneButton_pressed() -> void:
	Sounds.play("Select")
	ui_layer.go_back()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed('ui_accept'):
		get_tree().set_input_as_handled()
		_on_DoneButton_pressed()
