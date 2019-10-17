extends CanvasLayer

func _ready():
	show_screen("TitleScreen")

func show_screen(name: String, args: Array = []):
	hide_screen()
	var screen = get_node(name)
	screen.visible = true
	if screen.has_method("initialize"):
		screen.callv("initialize", args)

func hide_screen():
	for child in get_children():
		child.visible = false
