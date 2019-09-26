extends StaticBody2D

var GreenTwigs = preload("res://objects/cosmetic/GreenTwigs.tscn")
var Health = preload("res://objects/powerups/Health.tscn")
var Spread = preload("res://objects/powerups/Spread.tscn")

var contents = "health"

func _ready():
	$AnimationPlayer.play("glow")

func set_contents(_contents : String):
	contents = _contents

func take_damage(damage : int) -> void:
	rpc("open_crate")
	
remotesync func open_crate() -> void:
	var twigs = GreenTwigs.instance()
	twigs.position = position
	get_parent().add_child(twigs)
		
	var powerup
	
	match contents:
		"health":
			powerup = Health.instance()
		"spread":
			powerup = Spread.instance()
	
	powerup.set_name("Powerup")
	powerup.position = position
	get_parent().add_child(powerup)
	
	queue_free()
