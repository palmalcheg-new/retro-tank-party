extends Node

onready var idle_sound := $Idle
onready var fast_sound := $Fast
onready var tween := $Tween

enum EngineState {
	IDLE = 0,
	DRIVING = 1,
}

const IDLE_VOLUME_DB := -20.0
const DRIVING_VOLUME_DB := -10.0

const IDLE_PITCH_SCALE := 0.5
const DRIVING_PITCH_SCALE := 1.0

const TRANSITION_DURATION := 0.2
const TURNING_MODIFIER := 0.2

var engine_state: int = EngineState.IDLE setget set_engine_state
var turning := false

func _ready() -> void:
	fast_sound.volume_db = -40.0
	fast_sound.base_volume_db = DRIVING_VOLUME_DB
	idle_sound.volume_db = -40.0
	idle_sound.base_volume_db = IDLE_VOLUME_DB
	idle_sound.play()

func set_engine_state(_engine_state: int) -> void:
	if engine_state != _engine_state:
		engine_state = _engine_state
		
		tween.remove_all()
		
		if engine_state == EngineState.IDLE:
			tween.interpolate_property(fast_sound, "base_volume_db", DRIVING_VOLUME_DB, IDLE_VOLUME_DB, TRANSITION_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.interpolate_property(fast_sound, "pitch_scale", DRIVING_PITCH_SCALE, IDLE_PITCH_SCALE, TRANSITION_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		else:
			idle_sound.stop()
			
			fast_sound.volume_db = IDLE_VOLUME_DB
			fast_sound.pitch_scale = IDLE_PITCH_SCALE
			fast_sound.play()
			tween.interpolate_property(fast_sound, "base_volume_db", IDLE_VOLUME_DB, DRIVING_VOLUME_DB, TRANSITION_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.interpolate_property(fast_sound, "pitch_scale", IDLE_PITCH_SCALE, DRIVING_PITCH_SCALE, TRANSITION_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		
		tween.start()

func _on_Tween_tween_all_completed() -> void:
	if engine_state == EngineState.IDLE:
		fast_sound.stop()
		idle_sound.play()
	else:
		fast_sound.base_volume_db = DRIVING_VOLUME_DB
		fast_sound.pitch_scale = DRIVING_PITCH_SCALE

func _process(delta: float) -> void:
	if not tween.is_active():
		if turning:
			idle_sound.pitch_scale = IDLE_PITCH_SCALE + TURNING_MODIFIER
			fast_sound.pitch_scale = DRIVING_PITCH_SCALE + TURNING_MODIFIER
		else:
			idle_sound.pitch_scale = IDLE_PITCH_SCALE
			fast_sound.pitch_scale = DRIVING_PITCH_SCALE
