extends SGStaticBody2D

var GreenTwigs = preload("res://src/objects/cosmetic/GreenTwigs.tscn")

var contents: Pickup

func _ready():
	$AnimationPlayer.play("glow")

func _network_spawn(data: Dictionary) -> void:
	set_global_fixed_position(data['fixed_position'])
	contents = load(data['contents_path'])
	sync_to_physics_engine()

func take_damage(damage: int, attacker_id: int, attack_vector: SGFixedVector2) -> void:
	open_crate()

func open_crate() -> void:
	if get_parent() == null:
		return
	
	SyncManager.spawn('GreenTwigs', get_parent(), GreenTwigs, {
		fixed_position = fixed_position.copy(),
	})
	
	SyncManager.spawn('Powerup', get_parent(), contents.get_pickup_scene(), {
		fixed_position = fixed_position.copy(),
		pickup_path = contents.resource_path,
	}, false)
	
	SyncManager.despawn(self)
