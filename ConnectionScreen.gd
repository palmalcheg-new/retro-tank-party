extends Node2D

signal serve
signal connect

func _ready():
	pass

func _on_Serve_pressed() -> void:
	emit_signal("serve", $Name.text, int($Port.text))

func _on_Connect_pressed() -> void:
	emit_signal("connect", $Name.text, $Host.text, int($Port.text))
