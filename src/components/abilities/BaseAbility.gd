extends Reference

var tank
var ability_type
var charges := 1

func setup_ability(_tank, _ability_type) -> void:
	tank = _tank
	ability_type = _ability_type
	charges = ability_type.charges

func recharge_ability() -> void:
	if ability_type.rechargeable:
		charges += ability_type.charges

func attach_ability() -> void:
	pass

func detach_ability() -> void:
	pass

func get_ability_charges() -> int:
	return charges

func use_ability() -> void:
	pass
