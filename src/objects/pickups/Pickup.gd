extends SGArea2D

const Sound = preload("res://assets/sounds/Pickup__010.wav")

onready var collision_shape := $CollisionShape2D
onready var visual := $Visual

export (String) var letter := "P"
export (Color) var color := Color('#00ff00')

var _pickup

func _ready():
	$AnimationPlayer.play("shine")

func _network_spawn(data: Dictionary) -> void:
	_pickup = load(data['pickup_path'])
	visual = Globals.art.replace_visual("Pickup", visual, {
		pickup = _pickup,
		name = _pickup.get_pickup_machine_name(),
		color = color,
		letter = _pickup.letter,
	})
	
	fixed_position = data['fixed_position']
	sync_to_physics_engine()

func _network_process(delta: float, _input: Dictionary) -> void:
	var overlapping_bodies = get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		_on_Powerup_body_entered(overlapping_bodies[0])

func _on_Powerup_body_entered(body) -> void:
	if _pickup:
		_pickup.pickup(body)
	
	SyncManager.play_sound(str(get_path()), Sound, {
		position = global_position,
	})
	
	SyncManager.despawn(self)
