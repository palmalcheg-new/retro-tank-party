extends StaticBody2D

var GreenTwigs = preload("res://src/objects/cosmetic/GreenTwigs.tscn")

var contents: Pickup

func _ready():
	$AnimationPlayer.play("glow")

func set_contents(_contents: Pickup):
	contents = _contents

func take_damage(damage: int, attacker_id: int) -> void:
	rpc("open_crate")
	
remotesync func open_crate() -> void:
	var twigs = GreenTwigs.instance()
	twigs.position = position
	get_parent().add_child(twigs)
		
	var powerup = contents.instance()
	powerup.set_name("Powerup")
	powerup.position = position
	get_parent().add_child(powerup)
	
	queue_free()
