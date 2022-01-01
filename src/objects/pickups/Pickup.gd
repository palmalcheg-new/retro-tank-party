extends SGArea2D

const Sound = preload("res://assets/sounds/Pickup__010.wav")

onready var label := $Visual/OuterRect/InnerRect/Label
onready var outer_rect := $Visual/OuterRect
onready var collision_shape := $CollisionShape2D

export (String) var letter := "P" setget set_letter
export (Color) var color := Color('#00ff00') setget set_color

var _pickup

func _ready():
	$AnimationPlayer.play("shine")

func set_letter(_letter: String) -> void:
	if letter != _letter:
		letter = _letter
		if label == null:
			yield(self, "ready")
		label.text = _letter

func set_color(_color: Color) -> void:
	if label == null:
		yield(self, "ready")
	color = _color
	outer_rect.color = color
	label.add_color_override("font_color", color)

func setup_pickup(pickup) -> void:
	_pickup = pickup
	set_letter(pickup.letter)

func _network_spawn(data: Dictionary) -> void:
	fixed_position = data['fixed_position']
	setup_pickup(load(data['pickup_path']))
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
