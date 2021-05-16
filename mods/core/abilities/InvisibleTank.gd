extends "res://src/objects/tank/BaseTank.gd"

onready var default_modulate := modulate
onready var blink_timer := $BlinkTimer

var tank

func _ready() -> void:
	collision_shape.set_deferred("disabled", true)

func setup_invisible_tank(_tank) -> void:
	tank = _tank
	set_tank_color(tank.player_index)

func _physics_process(delta: float) -> void:
	if tank:
		global_position = tank.global_position
		global_rotation = tank.global_rotation
		turret_pivot.rotation = tank.turret_pivot.rotation

func start_blinking() -> void:
	if blink_timer.is_stopped():
		blink_timer.start()

func _on_BlinkTimer_timeout() -> void:
	# We blink by messing with the modulate.a because visible is used by
	# the ability scene to show the tank when it shoots or is hit.
	modulate.a = default_modulate.a if modulate.a == 0.0 else 0.0
