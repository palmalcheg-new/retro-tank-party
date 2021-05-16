extends "res://src/components/abilities/BaseAbility.gd"

const InvisibleTank = preload("res://mods/core/abilities/InvisibleTank.tscn")

onready var lifetime_timer := $LifetimeTimer
onready var warning_timer := $WarningTimer
onready var visible_timer := $VisibleTimer

var invisible_tank
var used := false

func attach_ability() -> void:
	tank.connect("shoot", self, "_on_tank_visible")
	tank.connect("hurt", self, "_on_tank_visible")
	tank.connect("weapon_type_changed", self, "_on_tank_weapon_changed")
	tank.connect("ability_type_changed", self, "_on_tank_ability_changed")

func detach_ability() -> void:
	tank.visible = true
	tank.disconnect("shoot", self, "_on_tank_visible")
	tank.disconnect("hurt", self, "_on_tank_visible")
	tank.disconnect("weapon_type_changed", self, "_on_tank_weapon_changed")
	tank.disconnect("ability_type_changed", self, "_on_tank_ability_changed")

func use_ability() -> void:
	if charges > 0:
		charges -= 1
		used = true
		
		tank.visible = false
		
		if tank.is_network_master():
			invisible_tank = InvisibleTank.instance()
			add_child(invisible_tank)
			invisible_tank.set_as_toplevel(true)
			invisible_tank.setup_invisible_tank(tank)
			
			warning_timer.start()
			lifetime_timer.start()

func mark_finished() -> void:
	if used:
		charges = 0
	else:
		.mark_finished()

func _on_tank_visible() -> void:
	if used:
		tank.visible = true
		if invisible_tank:
			invisible_tank.visible = false
		visible_timer.start()

func _on_tank_weapon_changed(weapon_type) -> void:
	if used and weapon_type != tank.BaseWeaponType:
		_on_tank_visible()

func _on_tank_ability_changed(ability_type) -> void:
	if used and ability_type != null:
		_on_tank_visible()

func _on_VisibleTimer_timeout() -> void:
	tank.visible = false
	if invisible_tank:
		invisible_tank.visible = true

func _on_WarningTimer_timeout() -> void:
	if invisible_tank:
		invisible_tank.start_blinking()

func _on_LifetimeTimer_timeout() -> void:
	if invisible_tank:
		invisible_tank.queue_free()
		invisible_tank = null

	if charges > 0:
		used = false
	else:
		emit_signal("finished")
