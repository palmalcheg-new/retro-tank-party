extends Node

onready var idle_sound = $Idle
onready var fast_sound = $Fast
onready var normal_sound = $Normal
onready var slow_sound = $Slow
onready var animation_player = $AnimationPlayer

enum EngineState {
	IDLE = 0,
	DRIVING = 1,
}

var engine_state: int = EngineState.IDLE setget set_engine_state

func _ready() -> void:
	idle_sound.play()

func set_engine_state(_engine_state: int) -> void:
	if engine_state != _engine_state:
		engine_state = _engine_state
		
		if engine_state == EngineState.IDLE:
			animation_player.play("switch_to_idle")
		else:
			animation_player.play("switch_to_driving")
