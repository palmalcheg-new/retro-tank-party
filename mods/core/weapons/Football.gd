extends "res://src/components/weapons/BaseWeapon.gd"

const Tank = preload("res://src/objects/Tank.gd")
const FootballSprite = preload("res://mods/core/modes/football/FootballSprite.tscn")

var sprite

func attach_weapon() -> void:
	sprite = FootballSprite.instance()
	sprite.name = 'Football'
	tank.bullet_start_position.add_child(sprite)

func detach_weapon() -> void:
	if sprite:
		tank.bullet_start_position.remove_child(sprite)
		sprite.queue_free()
		sprite = null

func _match_manager_pass_football(position: SGFixedVector2, vector: SGFixedVector2) -> void:
	var scene = tank.get_tree().get_current_scene()
	var match_manager = scene.get_node_or_null(@"MatchManager")
	if match_manager and match_manager.has_method('pass_football'):
		match_manager.pass_football(position, vector)

func fire_weapon() -> void:
	_match_manager_pass_football(tank.bullet_start_position.get_global_fixed_position(), SGFixed.vector2(SGFixed.ONE, 0).rotated(tank.turret_pivot.get_global_fixed_rotation()))

