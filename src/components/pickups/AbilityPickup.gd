extends "res://src/components/pickups/Pickup.gd"
class_name AbilityPickup

export (Resource) var ability_type

func get_default_pickup_scene() -> PackedScene:
	return preload("res://src/objects/pickups/AbilityPickup.tscn")

func pickup(tank) -> void:
	if tank.has_method('pickup_ability'):
		tank.pickup_ability(ability_type)
