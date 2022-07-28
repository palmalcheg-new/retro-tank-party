extends Node

var Steam = Engine.get_singleton("Steam")
var use_steam := Engine.has_singleton("Steam")
var steam_app_id := 1568570

func _ready() -> void:
	if Globals.arguments.get('disable-steam', false):
		use_steam = false
	if use_steam:
		if not _initialize_steam():
			use_steam = false
			set_process(false)

func _initialize_steam() -> bool:
	if Steam.restartAppIfNecessary(steam_app_id):
		get_tree().quit()
		return false

	var init: Dictionary = Steam.steamInit(false)
	if init['status'] != 1:
		OS.alert(init['verbal'] + " (%s)" % init['status'])
		get_tree().quit()
		return false

	if not Steam.isSubscribed():
		OS.alert("User does not own this game")
		get_tree().quit()
		return false

	#print ("Is connected to steam: %s" % Steam.loggedOn())
	#print ("Steam ID: %s" % Steam.getSteamID())

	return true

func _process(_delta: float) -> void:
	if use_steam:
		Steam.run_callbacks()
