extends "res://src/components/weapons/BaseWeapon.gd"

const FootballSprite = preload("res://mods/core/modes/football/FootballSprite.tscn")

var sprite

var previous_weapon_type: WeaponType

func attach_weapon() -> void:
	sprite = FootballSprite.instance()
	sprite.name = 'Football'
	tank.bullet_start_position.add_child(sprite)

func detach_weapon() -> void:
	if sprite:
		tank.bullet_start_position.remove_child(sprite)
		sprite.queue_free()
		sprite = null

func fire_weapon() -> void:
	detach_weapon()
	
	var scene = tank.get_tree().get_current_scene()
	if scene.has_node('MatchManager'):
		var match_manager = scene.get_node('MatchManager')
		if match_manager.has_method('pass_football'):
			match_manager.rpc("pass_football", tank.bullet_start_position.global_position, tank.turret_pivot.global_rotation)
	
	tank.call_deferred("set_weapon_type", previous_weapon_type)
