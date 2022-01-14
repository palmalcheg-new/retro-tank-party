extends Node2D

onready var label := $OuterRect/InnerRect/Label
onready var outer_rect := $OuterRect

func attach_visual(info: Dictionary) -> void:
	label.text = info['letter']
	
	var color = info['color']
	outer_rect.color = color
	label.add_color_override("font_color", color)
