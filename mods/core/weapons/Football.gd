extends "res://src/components/weapons/BaseWeapon.gd"

const FootballSprite = preload("res://mods/core/modes/football/FootballSprite.tscn")

var sprite

var previous_weapon_type: WeaponType

func attach_weapon() -> void:
	sprite = FootballSprite.instance()
	sprite.name = 'Football'
	tank.bullet_start_position.add_child(sprite)

func detach_weapon() -> void:
	tank.bullet_start_position.remove_child(sprite)
	sprite.queue_free()

func fire_weapon() -> void:
	detach_weapon()
	.fire_weapon()
	tank.set_weapon_type(previous_weapon_type)

