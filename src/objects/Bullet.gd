extends "res://src/components/weapons/BaseBullet.gd"

onready var visual = $BulletPivot/Visual

var speed = 1529173 # ~23.33

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	visual = Globals.art.replace_visual("TankBullet", visual, {
		player_index = player_index,
	})

func explode(type: String) -> void:
	.explode(type)
	SyncManager.despawn(self)
	lifetime_timer.stop()

func _network_process(delta: float, _input: Dictionary) -> void:
	._network_process(delta, _input)
	
	# If we've already exploded, then we don't bother moving.
	if not is_inside_tree():
		return
	
	# @todo Is there a way to pre-calculate the vector * speed without losing
	#       flexibility in child classes?
	fixed_position.iadd(vector.mul(speed))
	sync_to_physics_engine()
	check_collision()

func _on_LifetimeTimer_timeout() -> void:
	explode("Smoke")
