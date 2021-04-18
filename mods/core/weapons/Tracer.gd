extends "res://src/components/weapons/BaseWeapon.gd"

const TracerDetector = preload("res://mods/core/weapons/TracerDetector.tscn")

var detector

func attach_weapon() -> void:
	detector = TracerDetector.instance()
	detector.name = 'TracerDetector'
	tank.bullet_start_position.add_child(detector)
	detector.setup_tracer_detector(tank)

func detach_weapon() -> void:
	tank.bullet_start_position.remove_child(detector)
	detector.queue_free()

func fire_weapon() -> void:
	var bullet = create_bullet()
	bullet.target = detector.get_tracer_target()
