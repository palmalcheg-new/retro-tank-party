extends Node2D

var tank
var ability_type

signal finished ()

func setup_ability(_tank, _ability_type) -> void:
	tank = _tank
	ability_type = _ability_type

func _network_despawn() -> void:
	mark_finished()

func attach_ability() -> void:
	pass

func detach_ability() -> void:
	pass

func mark_finished() -> void:
	emit_signal("finished")

func use_ability() -> void:
	pass
