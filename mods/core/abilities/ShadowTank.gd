extends "res://src/objects/tank/BaseTank.gd"

func setup_shadow_tank(tank) -> void:
	body_sprite.region_rect = TANK_COLORS[tank.player_index]['body_sprite_region']
	turret_sprite.region_rect = TANK_COLORS[tank.player_index]['turret_sprite_region']
	global_position = tank.global_position
	global_rotation = tank.global_rotation
	turret_pivot.rotation = tank.turret_pivot.rotation
	collision_shape.set_deferred("disabled", true)

func _on_Timer_timeout() -> void:
	queue_free()
