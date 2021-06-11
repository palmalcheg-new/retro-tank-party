extends Area2D

const DropCrate = preload("res://src/objects/DropCrate.tscn")

const CRATE_SIZE = Vector2(60, 60)

onready var collision_shape = $CollisionShape2D
onready var drop_timer = $DropTimer
onready var spawns = $Spawns

var possible_contents := []
var detector

func map_object_start(map, game):
	if is_network_master():
		possible_contents = game.possible_pickups
		detector = game.create_free_space_detector()
		detector.connect("free_space_found", self, "_on_free_space_found")
		drop_timer.start()

func map_object_stop(map, game):
	drop_timer.stop()
	if detector:
		detector.stop_detecting()
		detector.queue_free()
	clear()

func has_drop_crate_or_powerup() -> bool:
	return spawns.has_node("DropCrate") or spawns.has_node("Powerup")

func spawn_drop_crate() -> void:
	if not is_network_master():
		return
	if not has_drop_crate_or_powerup():
		var extents = collision_shape.shape.extents
		var area = Rect2(global_position - extents, extents * 2.0)
		detector.start_detecting(area, CRATE_SIZE)

func _on_DropTimer_timeout() -> void:
	spawn_drop_crate()

func _on_free_space_found(crate_position) -> void:
	var contents = possible_contents[randi() % possible_contents.size()]
	rpc("_do_spawn_drop_crate", crate_position, contents.resource_path)

remotesync func _do_spawn_drop_crate(_position: Vector2, pickup_path: String):
	var crate = DropCrate.instance()
	crate.name = 'DropCrate'
	spawns.add_child(crate)
	crate.global_position = _position
	crate.set_contents(load(pickup_path))

func clear():
	for child in spawns.get_children():
		remove_child(child)
		child.queue_free()
