extends HBoxContainer

var MedalTexture = preload("res://assets/medal2.png")
var JoystickTexture = preload("res://assets/joystickRight.png")

onready var name_label := $NameLabel
onready var status_label := $StatusLabel
onready var host_icon := $HostIcon
onready var spectator_icon := $SpectatorIcon
onready var ping_label := $PingLabel

var status := "" setget set_status
var host := false setget set_host
var spectator := false setget set_spectator

func _ready() -> void:
	ping_label.visible = false
	set_spectator(false)

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

func set_spectator(_spectator: bool) -> void:
	spectator = _spectator
	if not spectator:
		spectator_icon.texture = JoystickTexture
	else:
		spectator_icon.texture = null

func set_ping_time(rtt: int) -> void:
	ping_label.visible = true
	ping_label.text = tr("PLAYER_PING") % rtt
