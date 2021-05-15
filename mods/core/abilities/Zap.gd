extends "res://src/components/abilities/BaseAbility.gd"

const ZapAttachment = preload("res://mods/core/abilities/ZapAttachment.tscn")

var game
var detector
var attachment

var map_rect: Rect2
var tank_size := Vector2(128, 128)

func attach_ability() -> void:
	game = tank.game
	map_rect = game.map.get_map_rect()
	detector = game.create_free_space_detector()
	detector.connect("free_space_found", self, "_on_free_space_found")
	
	attachment = ZapAttachment.instance()
	tank.add_child(attachment)
	attachment.setup_attachment(tank)

func detach_ability() -> void:
	detector.queue_free()
	attachment.queue_free()

func use_ability() -> void:
	var next_position = detector.start_detecting(map_rect, tank_size)
	attachment.rpc("set_tank_visibility", false)

func _on_free_space_found(new_position) -> void:
	tank.position = new_position
	attachment.rpc("set_tank_visibility", true)
