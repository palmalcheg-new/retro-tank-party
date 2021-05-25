extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")

const VISIBLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const INVISIBLE_COLOR := Color(1.0, 1.0, 1.0, 0.38)

onready var lifetime_timer := $LifetimeTimer
onready var warning_timer := $WarningTimer
onready var visible_timer := $VisibleTimer
onready var blink_timer := $BlinkTimer

var tank_visible := true
var used := false

func attach_ability() -> void:
	tank.connect("shoot", self, "_on_tank_visible")
	tank.connect("hurt", self, "_on_tank_visible")
	tank.connect("weapon_type_changed", self, "_on_tank_weapon_changed")
	tank.connect("ability_type_changed", self, "_on_tank_ability_changed")
	tank.hooks.subscribe("send_remote_update", self, "_hook_tank_send_remote_update", 10)

func detach_ability() -> void:
	set_tank_visible(true)
	used = false
	tank.disconnect("shoot", self, "_on_tank_visible")
	tank.disconnect("hurt", self, "_on_tank_visible")
	tank.disconnect("weapon_type_changed", self, "_on_tank_weapon_changed")
	tank.disconnect("ability_type_changed", self, "_on_tank_ability_changed")
	tank.hooks.unsubscribe("send_remote_update", self, "_hook_tank_send_remote_update")

func use_ability() -> void:
	if charges > 0 and not used:
		charges -= 1
		used = true
		
		set_tank_visible(false)
		if tank.is_network_master():
			warning_timer.start()
			lifetime_timer.start()

func mark_finished() -> void:
	if used:
		charges = 0
	else:
		.mark_finished()

func set_tank_visible(_tank_visible: bool) -> void:
	tank_visible = _tank_visible
	if tank.is_network_master():
		tank.visible = true
		tank.modulate = VISIBLE_COLOR if tank_visible else INVISIBLE_COLOR
	else:
		tank.visible = tank_visible

func _hook_tank_send_remote_update(event: Tank.NetworkSyncEvent) -> void:
	# Rather than sending the tank node's visibility (which will change for
	# visual effect) we send the logic visibility per this powerup.
	event.data['visible'] = tank_visible

func _on_tank_visible() -> void:
	if used:
		set_tank_visible(true)
		visible_timer.start()

func _on_tank_weapon_changed(weapon_type) -> void:
	if used and weapon_type != tank.BaseWeaponType:
		_on_tank_visible()

func _on_tank_ability_changed(ability_type) -> void:
	if used and ability_type != null:
		_on_tank_visible()

func _on_VisibleTimer_timeout() -> void:
	set_tank_visible(false)

func _on_WarningTimer_timeout() -> void:
	if blink_timer.is_stopped():
		blink_timer.start()

func _on_BlinkTimer_timeout() -> void:
	tank.visible = false if tank.visible else true

func _on_LifetimeTimer_timeout() -> void:
	blink_timer.stop()
	
	# Make sure we don't get stuck invisible
	set_tank_visible(true)

	if charges > 0:
		used = false
	else:
		emit_signal("finished")
