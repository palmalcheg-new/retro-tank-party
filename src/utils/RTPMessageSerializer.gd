extends "res://addons/network-sync-rollback/MessageSerializer.gd"

const Tank = preload("res://src/objects/Tank.gd")

const input_path_mapping := {
	'$': 0,
	'/root/Match/Game/Players/1': 1,
	'/root/Match/Game/Players/2': 2,
	'/root/Match/Game/Players/3': 3,
	'/root/Match/Game/Players/4': 4,
	'/root/Practice/Game/Players/1': 1,
}

enum HeaderFlags {
	RETRO_CONTROLS = 0x01,
	HAS_INPUT_VECTOR = 0x02,
	HAS_TURRET_ROTATION = 0x04,
	SHOOTING = 0x08,
	USING_ABILITY = 0x10,
}

func serialize_input(all_input: Dictionary) -> PoolByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(32)
	
	buffer.put_u8(all_input.size())
	for path in all_input:
		var mapped_path = input_path_mapping[path]
		buffer.put_u8(mapped_path)
		if mapped_path == 0:
			buffer.put_u32(all_input[path])
			continue
		
		var input = all_input[path]
		
		var header: int = 0
		if input.get(Tank.PlayerInput.CONTROL_SCHEME, GameSettings.ControlScheme.MODERN) == GameSettings.ControlScheme.RETRO:
			header |= HeaderFlags.RETRO_CONTROLS
		if input.has(Tank.PlayerInput.INPUT_VECTOR):
			header |= HeaderFlags.HAS_INPUT_VECTOR
		if input.has(Tank.PlayerInput.TURRET_ROTATION):
			header |= HeaderFlags.HAS_TURRET_ROTATION
		if input.get(Tank.PlayerInput.SHOOTING, false):
			header |= HeaderFlags.SHOOTING
		if input.get(Tank.PlayerInput.USING_ABILITY, false):
			header |= HeaderFlags.USING_ABILITY
		
		buffer.put_u8(header)
		
		if input.has(Tank.PlayerInput.TURRET_ROTATION):
			buffer.put_64(input.get(Tank.PlayerInput.TURRET_ROTATION, 0))
		
		if input.has(Tank.PlayerInput.INPUT_VECTOR):
			var input_vector: SGFixedVector2 = input[Tank.PlayerInput.INPUT_VECTOR]
			buffer.put_64(input_vector.x)
			buffer.put_64(input_vector.y)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PoolByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input := {}
	
	var path_count = buffer.get_u8()
	for path_index in range(path_count):
		var mapped_path = buffer.get_u8()
		if mapped_path == 0:
			all_input['$'] = buffer.get_u32()
			continue
		
		var input := {}
		
		var header = buffer.get_u8()
		if header & HeaderFlags.RETRO_CONTROLS:
			input[Tank.PlayerInput.CONTROL_SCHEME] = GameSettings.ControlScheme.RETRO
		if header & HeaderFlags.SHOOTING:
			input[Tank.PlayerInput.SHOOTING] = true
		if header & HeaderFlags.USING_ABILITY:
			input[Tank.PlayerInput.USING_ABILITY] = true
		
		if header & HeaderFlags.HAS_TURRET_ROTATION:
			input[Tank.PlayerInput.TURRET_ROTATION] = buffer.get_64()
		
		if header & HeaderFlags.HAS_INPUT_VECTOR:
			input[Tank.PlayerInput.INPUT_VECTOR] = SGFixed.vector2(
				buffer.get_64(),
				buffer.get_64())
		
		var path = '/root/Match/Game/Players/' + str(mapped_path)
		all_input[path] = input
	
	return all_input
