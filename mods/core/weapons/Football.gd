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

func detach_weapon() -> void:
	tank.hooks.unsubscribe("pickup_weapon", self, "_hook_tank_pickup_weapon")
	if sprite:
		tank.bullet_start_position.remove_child(sprite)
		sprite.queue_free()
		sprite = null

func _hook_tank_pickup_weapon(event: Tank.PickupWeaponEvent) -> void:
	# Stash any new powerup for later.
	previous_weapon_type = event.weapon_type
	event.stop_propagation()

func fire_weapon() -> void:
	detach_weapon()
	
	var scene = tank.get_tree().get_current_scene()
	if scene.has_node('MatchManager'):
		var match_manager = scene.get_node('MatchManager')
		if match_manager.has_method('pass_football'):
			match_manager.rpc("pass_football", tank.bullet_start_position.global_position, tank.turret_pivot.global_rotation)
	
	tank.call_deferred("set_weapon_type", previous_weapon_type)
