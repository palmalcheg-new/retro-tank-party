extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")
const HidingSound = preload("res://assets/sounds/Teleport__006.wav")
const ShowingSound = preload("res://assets/sounds/Teleport__010.wav")

onready var rng := $RandomNumberGenerator

const TANK_DIMENSION = SGFixed.ONE * 128
const SCALE_INCREMENT := 8192
const SCALE_FRAME_COUNT := 8
const MOVE_FRAME_COUNT := 30

var game

var detector
var map_rect: Rect2

enum ZapStage {
	NONE,
	HIDING,
	MOVING,
	SHOWING,
}

var zap_stage = ZapStage.NONE
var frame_counter := 0
var destination: SGFixedVector2
var move_increment: SGFixedVector2
var current_scale := SGFixed.ONE

func attach_ability() -> void:
	game = tank.game
	
	tank.hooks.subscribe("calculate_movement_vector", self, "_hook_tank_prevent_default", -1000)
	tank.hooks.subscribe("shoot", self, "_hook_tank_prevent_default", -1000)
	tank.hooks.subscribe("use_ability", self, "_hook_tank_prevent_default", -1000)

func detach_ability() -> void:
	tank.collision_shape.disabled = false
	tank.player_info_node.visible = true
	
	if detector:
		detector.queue_free()
		detector = null
	
	tank.hooks.unsubscribe("calculate_movement_vector", self, "_hook_tank_prevent_default")
	tank.hooks.unsubscribe("shoot", self, "_hook_tank_prevent_default")
	tank.hooks.unsubscribe("use_ability", self, "_hook_tank_prevent_default")

func use_ability() -> void:
	rng.set_seed(game.generate_random_seed())
	
	detector = game.create_free_space_detector(
		game.map.get_map_fixed_rect(),
		SGFixed.vector2(TANK_DIMENSION, TANK_DIMENSION),
		rng)
	destination = detector.detect_free_space()
	move_increment = destination.sub(tank.get_global_fixed_position()).div(MOVE_FRAME_COUNT * SGFixed.ONE)
	current_scale = SGFixed.ONE
	
	tank.collision_shape.disabled = true
	
	if not tank.is_network_master():
		tank.player_info_node.visible = false
	
	SyncManager.play_sound(str(get_path()), HidingSound, {
		position = global_position,
	})
	
	_change_stage(ZapStage.HIDING, SCALE_FRAME_COUNT)

func _change_stage(new_stage, frame_count) -> void:
	zap_stage = new_stage
	frame_counter = frame_count

func _save_state() -> Dictionary:
	return {
		zap_stage = zap_stage,
		frame_counter = frame_counter,
		destination = destination.copy(),
		move_increment = move_increment.copy(),
		current_scale = current_scale,
		tank_collision_shape_disabled = tank.collision_shape.disabled,
		_tank_player_info_node_visible = tank.player_info_node.visible,
	}

func _load_state(state: Dictionary) -> void:
	zap_stage = state['zap_stage']
	frame_counter = state['frame_counter']
	destination = state['destination'].copy()
	move_increment = state['move_increment'].copy()
	current_scale = state['current_scale']
	tank.collision_shape.disabled = state['tank_collision_shape_disabled']
	tank.player_info_node.visible = state['_tank_player_info_node_visible']

func _network_process(delta: float, input: Dictionary) -> void:
	if zap_stage == ZapStage.NONE:
		return
	
	if frame_counter > 0:
		if zap_stage == ZapStage.HIDING:
			if current_scale > SCALE_INCREMENT:
				current_scale -= SCALE_INCREMENT
				tank.fixed_scale = SGFixed.vector2(current_scale, current_scale)
		elif zap_stage == ZapStage.MOVING:
			tank.fixed_position.iadd(move_increment)
		elif zap_stage == ZapStage.SHOWING:
			if current_scale < SGFixed.ONE:
				current_scale += SCALE_INCREMENT
				tank.fixed_scale = SGFixed.vector2(current_scale, current_scale)
		tank.sync_to_physics_engine()
		frame_counter -= 1
	else:
		if zap_stage == ZapStage.HIDING:
			tank.visible = false
			_change_stage(ZapStage.MOVING, MOVE_FRAME_COUNT)
		elif zap_stage == ZapStage.MOVING:
			tank.set_global_fixed_position(destination)
			tank.fixed_scale = SGFixed.vector2(SCALE_INCREMENT, SCALE_INCREMENT)
			tank.visible = true
			tank.player_info_node.visible = true
			tank.collision_shape.disabled = false
			tank.sync_to_physics_engine()
			SyncManager.play_sound(str(get_path()), ShowingSound, {
				position = global_position,
			})
			_change_stage(ZapStage.SHOWING, SCALE_FRAME_COUNT)
		elif zap_stage == ZapStage.SHOWING:
			tank.fixed_scale = SGFixed.vector2(SGFixed.ONE, SGFixed.ONE)
			tank.sync_to_physics_engine()
			_change_stage(ZapStage.NONE, 0)
			mark_finished()

func _hook_tank_prevent_default(event: Tank.TankEvent) -> void:
	event.stop_propagation()
