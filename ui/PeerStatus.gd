extends HBoxContainer

func _ready():
	pass

func initialize(name, status = "Connecting..."):
	$NameLabel.text = name
	$StatusLabel.text = status

func set_status(status):
	$StatusLabel.text = status
