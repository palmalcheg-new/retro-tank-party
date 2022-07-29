extends Control

onready var credits_team = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/CreditsTeam
onready var credits_legal = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/CreditsLegal

func _ready() -> void:
	update_translation()
	update_legal()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_translation()

func update_translation() -> void:
	if credits_team != null:
		credits_team.bbcode_text = tr("CREDITS_TEAM")

func update_legal() -> void:
	var t = "\n"

	t += "[b]Engine Components:[/b]\n------------------------\n\n"
	for item in Engine.get_copyright_info():
		t += "[b]%s[/b]\n\n[color=black]" % item.name
		for part in item.parts:
			for holder in part.copyright:
				t += "Copyright (c) %s\n" % holder
			t += "License: %s\n\n" % part.license
		t += "[/color]\n"

	t += "[b]Licenses:[/b]\n------------\n\n"
	var licenses = Engine.get_license_info()
	for item in licenses:
		t += "[b]%s[/b]\n\n" % item
		t += "[color=black]%s[/color]\n\n" % licenses[item]

	credits_legal.bbcode_text = t


func _on_Credits_meta_clicked(meta) -> void:
	# Open links in the web browser.
	OS.shell_open(str(meta))
