extends Node

var player_joy_id := 0

var rumble := 0.0
var weak_rumble := 0.0
var rumble_decay := 0.8
var rumble_variation := 0.2
var rumble_duration := 0.017

var ticks := {}

func _ready() -> void:
	SyncManager.connect("tick_retired", self, "_on_SyncManager_tick_retired")
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")

func _physics_process(delta: float) -> void:
	if rumble > 0.0:
		rumble = max(rumble - rumble_decay * delta, 0)
	if weak_rumble > 0.0:
		weak_rumble = max(weak_rumble - rumble_decay * delta, 0)
	
	if rumble > 0.0 or weak_rumble > 0.0:
		_do_rumble()

func _do_rumble() -> void:
	var strong_magnitude := 0.0
	var weak_magnitude := 0.0
	if rumble > 0.0:
		strong_magnitude = min(1.0, rumble + (randf() * rumble_variation))
		weak_magnitude = min(1.0, rumble + (randf() * rumble_variation))
	if weak_rumble > 0.0:
		weak_magnitude = min(1.0, weak_magnitude + weak_rumble)
	Input.start_joy_vibration(player_joy_id, weak_magnitude, strong_magnitude, rumble_duration)

func add_rumble(amount: float) -> void:
	# We allow multiple add_rumble() calls per frame if this isn't a rollback,
	# otherwise we only allow one, so we get something, while avoiding repeats.
	if ticks.has(SyncManager.current_tick) and SyncManager.is_in_rollback():
		return
	ticks[SyncManager.current_tick] = true
	
	rumble = min(1.0, rumble + amount)
	_do_rumble()

func add_weak_rumble(amount: float) -> void:
	weak_rumble = min(1.0, weak_rumble + amount)

func _on_SyncManager_tick_retired(tick) -> void:
	ticks.erase(tick)

func _on_SyncManager_sync_stopped() -> void:
	ticks.clear()
