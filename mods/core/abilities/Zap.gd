extends "res://src/components/abilities/BaseAbility.gd"

const ZapAttachment = preload("res://mods/core/abilities/ZapAttachment.tscn")

const TANK_SIZE := Vector2(128, 128)

var game
var detector
var attachment

var map_rect: Rect2

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
	detector.start_detecting(map_rect, TANK_SIZE)

func _on_free_space_found(new_position) -> void:
	attachment.zap(new_position)
