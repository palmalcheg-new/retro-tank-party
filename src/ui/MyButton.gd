extends Button

onready var hover_sound := $HoverSound
onready var click_sound := $ClickSound

func _ready() -> void:
	self.connect("mouse_entered", self, "_on_mouse_entered")
	self.connect("mouse_exited", self, "_on_mouse_exited")
	self.connect("pressed", self, "_on_pressed")

func _on_mouse_entered() -> void:
	if hover_sound:
		hover_sound.play()

func _on_mouse_exited() -> void:
	pass

func _on_pressed() -> void:
	if click_sound:
		click_sound.play()

