extends SGArea2D

const DropCrate = preload("res://src/objects/DropCrate.tscn")

# 3932160 = 60
const CRATE_DIMENSION = 3932160
const TWO = 131072

onready var collision_shape = $CollisionShape2D
onready var drop_timer = $DropTimer
onready var spawns = $Spawns
onready var rng = $RandomNumberGenerator

var possible_contents := []
var detector

func map_object_start(map, game):
	rng.set_seed(game.generate_random_seed())
	possible_contents = game.possible_pickups
	
	var extents = collision_shape.shape.extents
	var area = SGFixed.rect2(get_global_fixed_position().sub(extents), extents.mul(TWO))
	detector = game.create_free_space_detector(
		area,
		SGFixed.vector2(CRATE_DIMENSION, CRATE_DIMENSION),
		rng)
	
	drop_timer.start()

func map_object_stop(map, game):
	drop_timer.stop()
	if detector:
		detector.queue_free()
		detector = null
	clear()

func has_drop_crate_or_powerup() -> bool:
	return spawns.has_node("DropCrate") or spawns.has_node("Powerup")

func spawn_drop_crate() -> void:
	if not has_drop_crate_or_powerup():
		var crate_position = detector.detect_free_space()
		var contents = possible_contents[rng.randi() % possible_contents.size()]
		
		SyncManager.spawn('DropCrate', spawns, DropCrate, {
			fixed_position = crate_position.copy(),
			contents_path = contents.resource_path,
		}, false)

func _on_DropTimer_timeout() -> void:
	spawn_drop_crate()

func clear():
	for child in spawns.get_children():
		SyncManager.despawn(child)
