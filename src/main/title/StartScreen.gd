extends "res://src/ui/Screen.gd"

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# To prevent confusion, we only recognize buttons from the configured
	# gamepad, so that some random gamepad doesn't work on this screen, but then
	# fail to work on any other UIs.
	if event is InputEventKey or (event is InputEventJoypadButton and event.device == GameSettings.joy_id) or event is InputEventMouseButton:
		Sounds.play("Select")
		ui_layer.show_screen("MenuScreen")
		get_tree().set_input_as_handled()
