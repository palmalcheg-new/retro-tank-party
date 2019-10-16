extends Control

var PeerStatus = preload("res://PeerStatus.tscn");

var connected = {}

func _ready():
	for child in $Panel/VBoxContainer.get_children():
		child.queue_free()
	$Panel/ReadyButton.disabled = true

func initialize(users):
	for k in users.keys():
		var u = users[k];
		var status = PeerStatus.instance()
		status.initialize(u['username'])
		status.name = u['username']
		$Panel/VBoxContainer.add_child(status)
		connected[u['username']] = false

func set_status_connected(username):
	$Panel/VBoxContainer.get_node(username).set_status("CONNECTED!")
	connected[username] = true

	# Check if all connected, and if so, activate the button.	
	for v in connected.values():
		if not v:
			return
	$Panel/ReadyButton.disabled = false
