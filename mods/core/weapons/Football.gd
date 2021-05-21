extends "res://src/components/weapons/BaseWeapon.gd"

const Tank = preload("res://src/objects/Tank.gd")
const FootballSprite = preload("res://mods/core/modes/football/FootballSprite.tscn")

var sprite

var previous_weapon_type: WeaponType

func attach_weapon() -> void:
	sprite = FootballSprite.instance()
	sprite.name = 'Football'
	tank.bullet_start_position.add_child(sprite)
	tank.hooks.subscribe("pickup_weapon", self, "_hook_tank_pickup_weapon", -10)
	tank.connect("hurt", self, "_on_tank_hurt")
	tank.connect("player_dead", self, "_on_tank_dead")

func detach_weapon() -> void:
	tank.hooks.unsubscribe("pickup_weapon", self, "_hook_tank_pickup_weapon")
	tank.disconnect("hurt", self, "_on_tank_hurt")
	tank.disconnect("player_dead", self, "_on_tank_dead")
	if sprite:
		tank.bullet_start_position.remove_child(sprite)
		sprite.queue_free()
		sprite = null

func _match_manager_pass_football(position: Vector2, vector: Vector2):
	var scene = tank.get_tree().get_current_scene()
	if scene.has_node('MatchManager'):
		var match_manager = scene.get_node('MatchManager')
		if match_manager.has_method('pass_football'):
			match_manager.rpc("pass_football", position, vector)

func _hook_tank_pickup_weapon(event: Tank.PickupWeaponEvent) -> void:
	# Stash any new powerup for later.
	previous_weapon_type = event.weapon_type
	event.stop_propagation()

func _on_tank_hurt(damage: int, attacker_id: int, attack_vector: Vector2) -> void:
	tank.set_weapon_type(null)
	_match_manager_pass_football(tank.global_position, attack_vector)

func _on_tank_dead(killed_id: int) -> void:
	tank.set_weapon_type(null)
	_match_manager_pass_football(tank.global_position, Vector2.ZERO)

func fire_weapon() -> void:
	detach_weapon()
	
	_match_manager_pass_football(tank.bullet_start_position.global_position, Vector2.RIGHT.rotated(tank.turret_pivot.global_rotation))
	
	tank.call_deferred("set_weapon_type", previous_weapon_type)
