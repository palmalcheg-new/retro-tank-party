extends Resource
class_name WeaponType

export (Script) var weapon_script: Script = preload("res://src/components/weapons/BaseWeapon.gd")
export (PackedScene) var bullet_scene: PackedScene = preload("res://src/objects/Bullet.tscn")
export (int) var damage := 10
