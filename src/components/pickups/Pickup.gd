extends Resource
class_name Pickup

export (String) var name := ''
export (String) var letter := 'P'
export (int) var rarity := 20
export (PackedScene) var pickup_scene: PackedScene = preload("res://src/objects/pickups/Pickup.tscn")

func instance() -> Node2D:
	var pickup = pickup_scene.instance()
	pickup.setup_pickup(self)
	return pickup

# This needs to be overridden by the child resource class.
func pickup(tank) -> void:
	pass
