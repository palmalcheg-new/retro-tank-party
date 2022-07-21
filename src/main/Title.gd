extends Node2D

onready var ui_layer = $UILayer

func _ready() -> void:
	# For some reason, we don't get the language from Steam until later, so
	# if we're using Steam, try again to determine the default language.
	if SteamManager.use_steam and GameSettings.language == 'default':
		GameSettings.update_language()

	if "replay" in OS.get_cmdline_args():
		get_tree().change_scene("res://src/main/Match.tscn")
		return
	if Globals.arguments.has('join'):
		get_tree().change_scene("res://src/main/SessionSetup.tscn")
		return

	if not Globals.title_shown:
		ui_layer.show_screen("StartScreen")
		Globals.title_shown = true
	else:
		ui_layer.show_screen("MenuScreen")

	Music.play("Title")

func _on_UILayer_back_button() -> void:
	ui_layer.show_screen("MenuScreen")

func _on_UILayer_change_screen(name, screen, info) -> void:
	if name in ['StartScreen', 'MenuScreen']:
		ui_layer.hide_back_button()
	else:
		ui_layer.show_back_button()
