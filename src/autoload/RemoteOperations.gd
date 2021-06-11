extends Node

#
# This singleton allows the host to execute an operation on all clients,
# and to be notified once they have all finished executing that operation.
#

const TIMEOUT_SECONDS := 30
const FALLBACK_SCENE = "res://src/main/SessionSetup.tscn"

class HostOperation:
	var id: int
	var name: String
	var parent
	
	var done := {}
	var timestamp: int
	
	signal completed (success)
	
	func _init(_id: int, _name: String, _parent) -> void:
		id = _id
		parent = _parent
		timestamp = OS.get_system_time_secs()
	
	func cancel() -> void:
		parent._complete_operation(self, false)
	
	func mark_done(peer_id: int) -> void:
		done[peer_id] = true
		if check_done():
			parent._complete_operation(self, true)
	
	func check_done():
		for player in OnlineMatch.players.values():
			if not done.has(player.peer_id):
				return false
		return true

class ClientOperation:
	var id: int
	var parent
	
	func _init(_id: int, _parent) -> void:
		id = _id
		parent = _parent
	
	func mark_done(success: bool = true) -> void:
		parent.rpc_id(1, "_mark_done", id, success)

var _host_operations := {}
var _next_id := 0

func _ready() -> void:
	OnlineMatch.connect("player_left", self, "_on_OnlineMatch_player_left")
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	var timer = Timer.new()
	timer.autostart = true
	timer.connect("timeout", self, "_on_timer_timeout")
	add_child(timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Attempt to break circular reference
		_host_operations.clear()

func _validate_operation_name(name: String) -> bool:
	if not name.begins_with("_op_") or not has_method(name):
		return false
	return true

func perform_operation(name: String, info: Dictionary = {}):
	if not _validate_operation_name(name):
		return null
	if not get_tree().is_network_server():
		return null
	
	var operation = HostOperation.new(_next_id, name, self)
	_host_operations[_next_id] = operation
	_next_id += 1
	
	rpc("_perform_operation", operation.id, name, info)
	return operation

remotesync func _perform_operation(id: int, name: String, info: Dictionary) -> void:
	if not _validate_operation_name(name):
		return
	if get_tree().get_rpc_sender_id() != 1:
		return
	
	var operation = ClientOperation.new(id, self)
	call(name, operation, info)

master func _mark_done(id: int, success: bool) -> void:
	if not _host_operations.has(id):
		return
	
	var operation = _host_operations[id]
	if success:
		operation.mark_done(get_tree().get_rpc_sender_id())
	else:
		_complete_operation(operation, false)

func _complete_operation(operation: HostOperation, success: bool) -> void:
	_host_operations.erase(operation.id)
	operation.emit_signal("completed", success)

func _on_OnlineMatch_player_left(player: OnlineMatch.Player) -> void:
	# Re-check our list of operation to see if they are now completed, now that
	# we are no longer waiting on this host.
	for operation in _host_operations.values():
		if operation.check_done():
			_complete_operation(operation, true)

func _on_timer_timeout() -> void:
	var threshold = OS.get_system_time_secs() - TIMEOUT_SECONDS
	for operation in _host_operations.values():
		if operation.timestamp < threshold:
			_complete_operation(operation, false)

#
# The actual operations that we can execute.
#

func change_scene(path: String, info: Dictionary = {}) -> HostOperation:
	if not get_tree().is_network_server():
		return null
	
	# Cancel any other in-progress change scene operations.
	for other_operation in _host_operations:
		if other_operation.name == '_op_change_scene':
			other_operation.cancel()
	
	var full_info = {
		path = path,
		info = info,
	}
	var operation = perform_operation("_op_change_scene", full_info)
	if operation == null:
		return null
	
	operation.connect("completed", self, "_change_scene_host_operation_completed", [path])
	
	return operation

func _op_change_scene(operation: ClientOperation, full_info: Dictionary) -> void:
	var path = full_info['path']
	var info = full_info['info']
	
	if get_tree().change_scene(path) != OK:
		operation.mark_done(false)
		return
	
	# We need to defer so that the scene tree can fully update.
	call_deferred("_finish_op_change_scene", operation, info)

func _finish_op_change_scene(operation: ClientOperation, info: Dictionary) -> void:
	var scene = get_tree().current_scene
	if scene.has_method('scene_setup'):
		# We leave it up to the scene to mark the operation as done.
		scene.scene_setup(operation, info)
	else:
		operation.mark_done(true)

func _change_scene_host_operation_completed(success: bool, path: String) -> void:
	if not success:
		if get_tree().change_scene(FALLBACK_SCENE) != OK:
			OS.alert("Unable to change scene!")
			get_tree().quit(1)
		
		call_deferred("_change_scene_host_operation_total_failure", path)
		return
	
	var scene = get_tree().current_scene
	if scene.has_method('scene_start'):
		scene.scene_start()

func _change_scene_host_operation_total_failure(path: String) -> void:
	var scene = get_tree().current_scene
	scene.ui_layer.show_message("Unable to change scene: %s" % path)

func synchronized_rpc(node: Node, method: String, args: Array = [], pass_operation: bool = false):
	if node.has_method('_before_send_synchronized_rpc_method'):
		node._before_send_synchronized_rpc_method(method, args)
	
	var info := {
		node_path = str(node.get_path()),
		method = method,
		args = args,
		pass_operation = pass_operation
	}
	return perform_operation("_op_synchronized_rpc", info)

func _op_synchronized_rpc(operation: ClientOperation, info: Dictionary) -> void:
	var node_path = info['node_path']
	var method = info['method']
	var args = info['args']
	var pass_operation = info['pass_operation']
	
	var node = get_node(node_path)
	if not node or not is_instance_valid(node) or node.is_queued_for_deletion():
		push_warning("Synchronized RPC: Cannot find node at path: %s" % [node_path])
		return
	
	if not node.has_method('_get_synchronized_rpc_methods') or not node._get_synchronized_rpc_methods().has(method):
		push_error("Synchronized RPC: Method %s is not returned by %s._get_synchronized_rpc_methods()" % [method, node_path])
		return
	
	if node.has_method('_before_receive_synchronized_rpc_method'):
		node._before_receive_synchronized_rpc_method(method, args)
	
	if pass_operation:
		args.append(operation)
	
	node.callv(method, args)
	
	if not pass_operation:
		operation.mark_done()
