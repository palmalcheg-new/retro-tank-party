extends Reference

var tank
var weapon_type

func _init(_tank, _weapon_type) -> void:
	tank = tank
	weapon_type = _weapon_type

func attach_weapon() -> void:
	pass

func detach_weapon() -> void:
	pass

func create_bullet():
	var bullet = weapon_type.bullet_scene.instance()
	tank.get_parent().add_child(bullet)
	#bullet.setup(tank.get_network_master(), player_index, $TurretPivot/BulletStartPosition.global_position, $TurretPivot.global_rotation, target)
	return bullet

func fire_weapon() -> void:
	pass
