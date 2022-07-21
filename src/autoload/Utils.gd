extends Node

func save_node_transform_state(node: SGFixedNode2D, state: Dictionary) -> void:
	if node.fixed_position_x != 0:
		state['fixed_position_x'] = node.fixed_position_x
	if node.fixed_position_y != 0:
		state['fixed_position_y'] = node.fixed_position_y
	if node.fixed_rotation != 0:
		state['fixed_rotation'] = node.fixed_rotation
	if node.fixed_scale_x != SGFixed.ONE:
		state['fixed_scale_x'] = node.fixed_scale_x
	if node.fixed_scale_y != SGFixed.ONE:
		state['fixed_scale_y'] = node.fixed_scale_y

func load_node_transform_state(node: SGFixedNode2D, state: Dictionary) -> void:
	node.fixed_position_x = state.get('fixed_position_x', 0)
	node.fixed_position_y = state.get('fixed_position_y', 0)
	node.fixed_rotation = state.get('fixed_rotation', 0)
	if state.has('fixed_scale_x') or node.fixed_scale_x != SGFixed.ONE:
		node.fixed_scale_x = state.get('fixed_scale_x', SGFixed.ONE)
	if state.has('fixed_scale_y') or node.fixed_scale_y != SGFixed.ONE:
		node.fixed_scale_y = state.get('fixed_scale_y', SGFixed.ONE)

func interpolate_node_transform_state(node: SGFixedNode2D, old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	node.position = lerp(
		Vector2(SGFixed.to_float(old_state.get('fixed_position_x', 0)), SGFixed.to_float(old_state.get('fixed_position_y', 0))),
		Vector2(SGFixed.to_float(new_state.get('fixed_position_x', 0)), SGFixed.to_float(new_state.get('fixed_position_y', 0))),
		weight)

	node.rotation = lerp_angle(
		SGFixed.to_float(old_state.get('fixed_rotation', 0)),
		SGFixed.to_float(new_state.get('fixed_rotation', 0)),
		weight)

	node.scale = lerp(
		Vector2(SGFixed.to_float(old_state.get('fixed_scale_x', SGFixed.ONE)), SGFixed.to_float(old_state.get('fixed_scale_y', SGFixed.ONE))),
		Vector2(SGFixed.to_float(new_state.get('fixed_scale_x', SGFixed.ONE)), SGFixed.to_float(new_state.get('fixed_scale_y', SGFixed.ONE))),
		weight)

func translate_online_match_error(code: int, message: String, extra) -> String:
	var enum_name = OnlineMatch.ErrorCode.keys()[code]
	if code == OnlineMatch.ErrorCode.CLIENT_JOIN_ERROR:
		enum_name = OnlineMatch.JoinErrorReason.keys()[extra]
	if enum_name:
		return "ONLINE_MATCH_ERROR_" + enum_name
	return ''
