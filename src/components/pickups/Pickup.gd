extends Resource
class_name Pickup

export (String) var name := ''
export (String) var letter := 'P'
export (int) var rarity := 20
export (PackedScene) var pickup_scene

func get_default_pickup_scene() -> PackedScene:
	return preload("res://src/objects/pickups/Pickup.tscn")

func get_pickup_scene() -> PackedScene:
	if pickup_scene == null:
		return get_default_pickup_scene()
	return pickup_scene

# This needs to be overridden by the child resource class.
func pickup(tank) -> void:
	pass
