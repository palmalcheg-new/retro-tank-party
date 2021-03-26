extends Control

func _on_MadeInGodotVideo_finished() -> void:
	get_tree().change_scene("res://src/main/Title.tscn")
