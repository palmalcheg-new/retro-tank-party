extends "res://main/Screen.gd"

onready var screenshake_field := $Panel/VBoxContainer/GridContainer/ScreenshakeOptions
onready var network_relay_field := $Panel/VBoxContainer/GridContainer/NetworkRelayOptions

func _ready() -> void:
	screenshake_field.add_item("Disabled", 0)
	screenshake_field.add_item("Enabled", 1)
	screenshake_field.selected = 1 if GameSettings.use_screenshake else 0
	
	network_relay_field.add_item("Auto", OnlineMatch.NetworkRelay.AUTO)
	network_relay_field.add_item("Forced", OnlineMatch.NetworkRelay.FORCED)
	network_relay_field.add_item("Disabled", OnlineMatch.NetworkRelay.DISABLED)
	network_relay_field.selected = GameSettings.use_network_relay

func _show_screen(info: Dictionary = {}) -> void:
	screenshake_field.grab_focus()

func _hide_screen() -> void:
	GameSettings.save_settings()

func _on_ScreenshakeOptions_item_selected(index: int) -> void:
	GameSettings.use_screenshake = true if index == 1 else false

func _on_NetworkRelayOptions_item_selected(index: int) -> void:
	GameSettings.use_network_relay = index

func _on_DoneButton_pressed() -> void:
	ui_layer.show_screen("TitleScreen")
