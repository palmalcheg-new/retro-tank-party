extends "res://src/components/weapons/BaseWeapon.gd"

const FIVE_DEGREES = 5719

func fire_weapon() -> void:
	var turret_pivot = tank.turret_pivot
	var original_transform = turret_pivot.fixed_transform.copy()
	turret_pivot.fixed_rotation -= FIVE_DEGREES
	for i in range(3):
		create_bullet()
		turret_pivot.fixed_rotation += FIVE_DEGREES
	turret_pivot.fixed_transform = original_transform
