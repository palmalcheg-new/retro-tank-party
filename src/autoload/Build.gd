extends Node

#####
# NOTE: This file is replaced by the build system. DO NOT EDIT!
#####

var encryption_password := 'dev'
var fallback_ice_servers := [{ "urls": ["stun:stun.l.google.com:19302"] }]

#####
# NOTE: If you need to override these values (or do anything else custom on
#       your local dev copy, you should create a res://local.gd script that
#       extends Node and implement a setup_local() method.
#####

func _ready() -> void:
	if ResourceLoader.exists('res://local.gd'):
		var local = load('res://local.gd').new()
		add_child(local)
		if local.has_method('setup_local'):
			local.call_deferred('setup_local')
