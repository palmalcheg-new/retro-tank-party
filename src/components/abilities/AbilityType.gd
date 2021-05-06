extends Resource
class_name AbilityType

export (String) var name := ""
export (Script) var ability_script: Script = preload("res://src/components/abilities/BaseAbility.gd")
export (int) var charges := 1
export (bool) var rechargeable := true
