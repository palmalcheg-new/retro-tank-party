extends Resource
class_name Pickup

export (String) var name := ''
export (String) var letter := 'P'
export (int) var rarity := 20
export (PackedScene) var pickup_scene

func get_default_pickup_scene() -> PackedScene:
	return preload("res://src/objects/pickups/Pickup.tscn")

func instance() -> Node2D:
	if pickup_scene == null:
		pickup_scene = get_default_pickup_scene()
	var pickup = pickup_scene.instance()
	pickup.setup_pickup(self)
	return pickup

# This needs to be overridden by the child resource class.
func pickup(tank) -> void:
	pass
