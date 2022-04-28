extends SGStaticBody2D

export (String) var visual_id: String

func _ready() -> void:
	Globals.art.replace_visual(visual_id, $Visual)
