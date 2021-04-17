extends Area2D

var DropCrate = preload("res://src/objects/DropCrate.tscn")

var possible_contents = []

func _ready():
	# Build up a list of possible contents for drawing randomly.
	# @todo Can we store this in some global place?
	# @todo We only need to do this on the master
	for pickup_path in Modding.find_resources("pickups"):
		var pickup = load(pickup_path)
		for i in range(pickup.rarity):
			possible_contents.append(pickup)

func map_object_start():
	if is_network_master():
		$DropTimer.start()

func map_object_stop():
	clear()

func has_drop_crate_or_powerup() -> bool:
	return $Spawns.has_node("DropCrate") or $Spawns.has_node("Powerup")

func _on_DropTimer_timeout() -> void:
	if not has_drop_crate_or_powerup():
		var crate_position = Vector2()
		crate_position.x = (randi() % int($CollisionShape2D.shape.extents.x * 2)) - $CollisionShape2D.shape.extents.x
		crate_position.y = (randi() % int($CollisionShape2D.shape.extents.y * 2)) - $CollisionShape2D.shape.extents.y
		
		var contents = possible_contents[randi() % possible_contents.size()]
		rpc("spawn_drop_crate", crate_position, contents.resource_path)

remotesync func spawn_drop_crate(_position: Vector2, pickup_path: String):
	var crate = DropCrate.instance()
	crate.position = _position
	crate.set_name('DropCrate')
	crate.set_contents(load(pickup_path))
	$Spawns.add_child(crate)

func clear():
	$DropTimer.stop()
	for child in $Spawns.get_children():
		remove_child(child)
		child.queue_free()
