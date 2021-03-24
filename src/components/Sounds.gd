extends Node

func play(name: String):
	var node = get_node(name)
	assert(node != null, "No sound with name " + name)
	
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		node.play()
		return node
	elif node is Node:
		var players = []
		for child in node.get_children():
			if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
				players.append(child)
		players.shuffle()
		players[0].play()
		return players[0]
