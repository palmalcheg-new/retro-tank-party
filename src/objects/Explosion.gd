extends SGFixedNode2D

onready var animation_player = $AnimationPlayer

const MissSound = preload("res://assets/sounds/Snare__001.wav")
const HitSound = preload("res://assets/sounds/Explosion3__004.wav")
const BigSound = preload("res://assets/sounds/Explosion2__007.wav")

func _network_spawn(data: Dictionary) -> void:
	visible = true
	fixed_position = data['fixed_position']
	fixed_scale = SGFixed.vector2(data['scale'], data['scale'])
	
	var type = data['type']
	Globals.art.replace_visual('Explosion', $Visual, { type = type })
	
	animation_player.play("fire")
	
	# @todo Can we do something like this with rollback?
	#yield(get_tree().create_timer(randf() * 0.150), "timeout")
	
	var sound_id = str(get_path())
	if type == 'Smoke':
		SyncManager.play_sound(sound_id, MissSound, {
			position = global_position,
		})
	else:
		if data['scale'] > 1.0:
			SyncManager.play_sound(sound_id, BigSound, {
				volume_db = 2.0,
				position = global_position,
			})
		else:
			SyncManager.play_sound(sound_id, HitSound, {
				volume_db = 2.0,
				position = global_position,
			})

func _network_despawn() -> void:
	animation_player.stop(true)

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	visible = false
	SyncManager.despawn(self)
