extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")

const VISIBLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const INVISIBLE_COLOR := Color(1.0, 1.0, 1.0, 0.38)

onready var lifetime_timer := $LifetimeTimer
onready var warning_timer := $WarningTimer
onready var visible_timer := $VisibleTimer
onready var blink_timer := $BlinkTimer

func attach_ability() -> void:
	tank.connect("shoot", self, "_on_tank_shoot")
	tank.connect("hurt", self, "_on_tank_hurt")
	tank.connect("weapon_type_changed", self, "_on_tank_weapon_type_changed")
	tank.hooks.subscribe("pickup_weapon", self, "_hook_tank_pickup", -10)
	tank.hooks.subscribe("pickup_ability", self, "_hook_tank_pickup", -10)
	tank.hooks.subscribe("send_remote_update", self, "_hook_tank_send_remote_update", 10)

func detach_ability() -> void:
	set_tank_visible(true)
	lifetime_timer.stop()
	warning_timer.stop()
	visible_timer.stop()
	blink_timer.stop()
	tank.disconnect("shoot", self, "_on_tank_shoot")
	tank.disconnect("hurt", self, "_on_tank_hurt")
	tank.disconnect("weapon_type_changed", self, "_on_tank_weapon_type_changed")
	tank.hooks.unsubscribe("pickup_weapon", self, "_hook_tank_pickup")
	tank.hooks.unsubscribe("pickup_ability", self, "_hook_tank_pickup")
	tank.hooks.unsubscribe("send_remote_update", self, "_hook_tank_send_remote_update")

func use_ability() -> void:
	set_tank_visible(false)
	warning_timer.start()
	lifetime_timer.start()

func set_tank_visible(tank_visible: bool) -> void:
	if tank.is_network_master():
		tank.visible = true
		tank.modulate = VISIBLE_COLOR if tank_visible else INVISIBLE_COLOR
	else:
		tank.visible = tank_visible
		tank.player_info_node.visible = tank_visible

func expose_hidden_tank() -> void:
	set_tank_visible(true)
	visible_timer.start()

func _on_tank_shoot() -> void:
	expose_hidden_tank()

func _on_tank_hurt(damage, attacker_id, attack_vector) -> void:
	expose_hidden_tank()

func _on_tank_weapon_type_changed(weapon_type: WeaponType, old_weapon_type: WeaponType) -> void:
	if weapon_type != Tank.BaseWeaponType:
		expose_hidden_tank()

func _hook_tank_pickup(event) -> void:
	expose_hidden_tank()

func _on_VisibleTimer_timeout() -> void:
	set_tank_visible(false)

func _on_WarningTimer_timeout() -> void:
	if blink_timer.is_stopped():
		blink_timer.start()

func _on_BlinkTimer_timeout() -> void:
	if tank.is_network_master():
		tank.visible = false if tank.visible else true

func _on_LifetimeTimer_timeout() -> void:
	blink_timer.stop()
	
	# Make sure we don't get stuck invisible
	set_tank_visible(true)

	mark_finished()
