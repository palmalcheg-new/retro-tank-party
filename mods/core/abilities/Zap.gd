extends "res://src/components/abilities/BaseAbility.gd"

onready var tween := $Tween
onready var hiding_sound := $HidingSound
onready var showing_sound := $ShowingSound

const TANK_SIZE := Vector2(128, 128)

var game

var detector
var map_rect: Rect2

enum ZapStage {
	NONE,
	HIDING,
	HIDDEN,
	SHOWING,
}

var zap_stage = ZapStage.NONE
var destination: Vector2

func attach_ability() -> void:
	game = tank.game
	map_rect = game.map.get_map_rect()
	detector = game.create_free_space_detector()
	detector.connect("free_space_found", self, "_on_free_space_found")

func detach_ability() -> void:
	detector.queue_free()

func use_ability() -> void:
	if charges > 0 and zap_stage == ZapStage.NONE and not detector.detecting:
		detector.start_detecting(map_rect, TANK_SIZE)
		charges -= 1

func mark_finished() -> void:
	if zap_stage != ZapStage.NONE:
		charges = 0
	else:
		.mark_finished()

func _on_free_space_found(_destination) -> void:
	destination = _destination
	
	tank.collision_shape.set_deferred("disabled", true)
	tank.set_forced_input_vector(Vector2.ZERO)
	
	zap_stage = ZapStage.HIDING
	tween.interpolate_property(tank, "scale", Vector2(1.0, 1.0), Vector2.ZERO, 0.15)
	tween.start()
	
	if not tank.is_network_master():
		tank.player_info_node.visible = false
	
	hiding_sound.play()

func _on_Tween_tween_all_completed() -> void:
	if zap_stage == ZapStage.HIDING:
		zap_stage = ZapStage.HIDDEN
		tank.visible = false
		if tank.is_network_master():
			tween.interpolate_property(tank, "global_position", tank.global_position, destination, 1.0)
			tween.start()
		else:
			tank.global_position = destination
	elif zap_stage == ZapStage.HIDDEN:
		# Make sure this runs on all clients, because we aren't tweening on 
		# non-hosts.
		if tank.is_network_master():
			rpc("show_tank")
	elif zap_stage == ZapStage.SHOWING:
		zap_stage = ZapStage.NONE
		tank.collision_shape.set_deferred("disabled", false)
		tank.clear_forced_input_vector()
		
		if charges <= 0:
			emit_signal("finished")

remotesync func show_tank() -> void:
	zap_stage = ZapStage.SHOWING
	tank.visible = true
	tank.player_info_node.visible = true
	tween.interpolate_property(tank, "scale", Vector2.ZERO, Vector2(1.0, 1.0), 0.15)
	tween.start()
	showing_sound.play()
