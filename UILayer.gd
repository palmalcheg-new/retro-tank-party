extends CanvasLayer

func _ready():
	show_screen("TitleScreen")

func show_screen(name: String):
	hide_screen()
	get_node(name).visible = true

func hide_screen():
	for child in get_children():
		child.visible = false
