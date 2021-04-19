extends "res://src/components/weapons/BaseWeapon.gd"

func fire_weapon() -> void:
	var turret_pivot = tank.turret_pivot
	var original_rotation = turret_pivot.rotation
	turret_pivot.rotate(deg2rad(-5))
	for i in range(3):
		create_bullet()
		turret_pivot.rotate(deg2rad(5))
	turret_pivot.rotation = original_rotation
