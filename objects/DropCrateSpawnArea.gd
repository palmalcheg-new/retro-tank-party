extends Area2D

var DropCrate = preload("res://objects/DropCrate.tscn")

func _ready():
	pass

func start():
	$DropTimer.start()

func has_drop_crate_or_powerup() -> bool:
	return $Spawns.has_node("DropCrate") or $Spawns.has_node("Powerup")

func _on_DropTimer_timeout() -> void:
	if not has_drop_crate_or_powerup():
		var crate_position = Vector2()
		crate_position.x = (randi() % int($CollisionShape2D.shape.extents.x * 2)) - $CollisionShape2D.shape.extents.x
		crate_position.y = (randi() % int($CollisionShape2D.shape.extents.y * 2)) - $CollisionShape2D.shape.extents.y
		rpc("spawn_drop_crate", crate_position, "health")

remotesync func spawn_drop_crate(_position : Vector2, contents : String):
	var crate = DropCrate.instance()
	crate.position = _position
	crate.set_name('DropCrate')
	$Spawns.add_child(crate)

func clear():
	for child in $Spawns.get_children():
		remove_child(child)
		child.queue_free()
