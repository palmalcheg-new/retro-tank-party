extends "res://addons/godot-rollback-netcode/NakamaWebRTCNetworkAdaptor.gd"

func _init() -> void:
	._init()
	
	#.max_buffered_amount = 200
	max_skipped_input_in_a_row = 3
	# This is the max latency (~33ms * 15 = ~500ms)
	max_packet_lifetime = 500
