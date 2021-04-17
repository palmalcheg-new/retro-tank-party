extends Resource
class_name Pickup

export (String) var letter := 'P'
export (int) var rarity := 20
export (String, FILE, "*.tscn") var pickup_scene := "res://src/objects/pickups/Pickup.tscn"

var _pickup_scene_cached: PackedScene

func instance() -> Node2D:
	if not _pickup_scene_cached:
		_pickup_scene_cached = load(pickup_scene)
	var pickup = _pickup_scene_cached.instance()
	pickup.setup_pickup(self)
	return pickup

# This needs to be overridden by the child resource class.
func pickup(tank) -> void:
	pass
