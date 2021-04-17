extends Reference

var tank
var weapon_type

func setup_weapon(_tank, _weapon_type) -> void:
	tank = _tank
	weapon_type = _weapon_type

func attach_weapon() -> void:
	pass

func detach_weapon() -> void:
	pass

func create_bullet():
	var bullet = weapon_type.bullet_scene.instance()
	tank.get_parent().add_child(bullet)
	tank.setup_bullet(bullet)
	bullet.damage = weapon_type.damage
	return bullet

func fire_weapon() -> void:
	create_bullet()
