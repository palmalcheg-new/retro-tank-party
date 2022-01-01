extends Reference

var tank
var weapon_type

func setup_weapon(_tank, _weapon_type) -> void:
	tank = _tank
	weapon_type = _weapon_type

func teardown_weapon() -> void:
	pass

func attach_weapon() -> void:
	pass

func detach_weapon() -> void:
	pass

func create_bullet(info: Dictionary = {}):
	info['tank'] = tank
	info['weapon_type'] = weapon_type
	return SyncManager.spawn("Bullet", tank.get_parent(), weapon_type.bullet_scene, info)

func fire_weapon() -> void:
	create_bullet()
