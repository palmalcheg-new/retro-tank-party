extends SGFixedNode2D

onready var animation_player := $AnimationPlayer
onready var timer := $Timer

func _ready() -> void:
	Globals.art.replace_visual('GreenTwigs', $Visual)

func _network_spawn(data: Dictionary) -> void:
	fixed_position = data['fixed_position']
	timer.start()

func _network_despawn() -> void:
	timer.stop()
	animation_player.stop(true)
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_Timer_timeout() -> void:
	animation_player.play('Dissolve')

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == 'Dissolve':
		SyncManager.despawn(self)
