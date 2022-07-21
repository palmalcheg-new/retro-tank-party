extends Control

onready var credits_team = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/CreditsTeam

func _ready() -> void:
	update_translation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_translation()

func update_translation() -> void:
	if credits_team != null:
		credits_team.bbcode_text = tr("CREDITS_TEAM")

func _on_Credits_meta_clicked(meta) -> void:
	# Open links in the web browser.
	OS.shell_open(str(meta))
