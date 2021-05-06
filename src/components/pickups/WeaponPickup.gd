extends "res://src/components/pickups/Pickup.gd"
class_name WeaponPickup

export (Resource) var weapon_type

func get_default_pickup_scene() -> PackedScene:
	return preload("res://src/objects/pickups/WeaponPickup.tscn")

func pickup(tank) -> void:
	if tank.has_method('set_weapon_type'):
		tank.set_weapon_type(weapon_type)
