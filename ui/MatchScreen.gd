extends Control

signal find_match (min_players)
signal create_match ()
signal join_match (match_id)

func _ready():
	pass

func initialize() -> void:
	$PanelContainer/VBoxContainer/MatchPanel/SpinBox.value = 2
	$PanelContainer/VBoxContainer/JoinPanel/LineEdit.text = ''

func _on_MatchButton_pressed() -> void:
	emit_signal("find_match", $PanelContainer/VBoxContainer/MatchPanel/SpinBox.value)

func _on_CreateButton_pressed() -> void:
	emit_signal("create_match")

func _on_JoinButton_pressed() -> void:
	emit_signal("join_match", $PanelContainer/VBoxContainer/JoinPanel/LineEdit.text)

func _on_PasteButton_pressed() -> void:
	$PanelContainer/VBoxContainer/JoinPanel/LineEdit.text = OS.clipboard