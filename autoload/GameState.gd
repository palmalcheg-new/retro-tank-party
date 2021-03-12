extends Node

var online_play := false

var Steam = Engine.get_singleton("Steam")
var use_steam := Engine.has_singleton("Steam")
var steam_app_id := 1568570

func _ready() -> void:
	if use_steam:
		_initialize_steam()

func _initialize_steam() -> void:
	if Steam.restartAppIfNecessary(steam_app_id):
		get_tree().quit()
	
	var init: Dictionary = Steam.steamInit(false)
	if init['status'] != 1:
		OS.alert(init['verbal'] + " (%s)" % init['status'])
		get_tree().quit()
		return
	
	if not Steam.isSubscribed():
		OS.alert("User does not own this game")
		get_tree().quit()
		return
	
	#print ("Is connected to steam: %s" % Steam.loggedOn())
	#print ("Steam ID: %s" % Steam.getSteamID())

func _process(_delta: float) -> void:
	if use_steam:
		Steam.run_callbacks()

