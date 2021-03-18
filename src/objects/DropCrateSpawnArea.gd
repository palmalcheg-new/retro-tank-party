extends Area2D

var DropCrate = preload("res://src/objects/DropCrate.tscn")

func _ready():
	pass

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
		
		var contents
		match randi() % 10:
			0, 2, 4, 6, 8, 9:
				contents = "health"
			1, 3:
				contents = "spread"
			5, 7:
				contents = "target"
		rpc("spawn_drop_crate", crate_position, contents)

remotesync func spawn_drop_crate(_position : Vector2, contents : String):
	var crate = DropCrate.instance()
	crate.position = _position
	crate.set_name('DropCrate')
	crate.set_contents(contents)
	$Spawns.add_child(crate)

func clear():
	$DropTimer.stop()
	for child in $Spawns.get_children():
		remove_child(child)
		child.queue_free()
