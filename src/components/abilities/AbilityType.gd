extends Resource
class_name AbilityType

export (String) var name := ""
export (PackedScene) var ability_scene: PackedScene
export (int) var charges := 1
export (bool) var rechargeable := true
