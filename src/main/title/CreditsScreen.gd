extends Control

func _on_Credits_meta_clicked(meta) -> void:
	# Open links in the web browser.
	OS.shell_open(str(meta))
