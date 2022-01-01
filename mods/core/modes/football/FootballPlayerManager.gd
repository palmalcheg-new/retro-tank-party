extends Node

const Tank := preload("res://src/objects/Tank.gd")
const FootballWeaponType = preload("res://mods/core/weapons/football.tres")

onready var respawn_timer := $RespawnTimer

var player
var config: Dictionary
var game

var tank
var previous_weapon_type

signal respawn_player (player_id)

func setup_player_manager(_player, _config: Dictionary, _game) -> void:
	player = _player
	config = _config
	game = _game

func shutdown_player_manager() -> void:
	set_player_tank(null)

func _save_state() -> Dictionary:
	return {
		previous_weapon_type = previous_weapon_type,
	}

func _load_state(state: Dictionary) -> void:
	previous_weapon_type = state['previous_weapon_type']

func set_player_tank(_tank) -> void:
	if tank != null && is_instance_valid(tank):
		tank.hooks.unsubscribe("pickup_weapon", self, "_hook_tank_pickup_weapon")
		tank.disconnect("weapon_type_changed", self, "_on_tank_weapon_type_changed")
		tank.disconnect("player_dead", self, "_on_tank_player_dead")
	
	if tank != _tank:
		previous_weapon_type = null
	
	tank = _tank
	
	if tank:
		tank.hooks.subscribe("pickup_weapon", self, "_hook_tank_pickup_weapon", -10)
		tank.connect("weapon_type_changed", self, "_on_tank_weapon_type_changed")
		tank.connect("player_dead", self, "_on_tank_player_dead")

func _on_tank_player_dead(killer_id: int) -> void:
	set_player_tank(null)

func _on_tank_weapon_type_changed(weapon_type, old_weapon_type) -> void:
	# When we switch to the football, store the old weapon type.
	if weapon_type == FootballWeaponType:
		previous_weapon_type = old_weapon_type

func _hook_tank_pickup_weapon(event: Tank.PickupWeaponEvent) -> void:
	# If we pickup a weapon while already having the football, swap out the
	# stored weapon type to switch back to later.
	if tank.weapon_type == FootballWeaponType:
		previous_weapon_type = event.weapon_type
		event.stop_propagation()

func restore_previous_weapon() -> void:
	if tank:
		tank.set_weapon_type(previous_weapon_type)
		previous_weapon_type = null

func start_respawn_timer() -> void:
	respawn_timer.start()

func _on_RespawnTimer_timeout() -> void:
	emit_signal("respawn_player", player.peer_id)
