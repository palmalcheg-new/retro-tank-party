extends HBoxContainer

var MedalTexture = preload("res://assets/medal2.png")

onready var name_label := $NameLabel
onready var status_label := $StatusLabel
onready var host_icon := $HostIcon

var status := "" setget set_status
var host := false setget set_host

func initialize(_name: String, _status: String = "") -> void:
	name_label.text = _name
	self.status = _status

func set_status(_status: String) -> void:
	status = _status
	status_label.text = status

func set_host(_host: bool) -> void:
	host = _host
	if host:
		host_icon.texture = MedalTexture
	else:
		host_icon.texture = null
