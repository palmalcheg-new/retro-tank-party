extends SGKinematicBody2D

onready var body_visual := $BodyVisual
onready var turret_visual := $TurretPivot/TurretVisual
onready var turret_pivot := $TurretPivot
onready var bullet_start_position := $TurretPivot/BulletStartPosition
onready var collision_shape := $CollisionPolygon2D

func set_tank_color(index: int) -> void:
	body_visual = Globals.art.replace_visual("TankBody", body_visual, { player_index = index })
	turret_visual = Globals.art.replace_visual("TankTurret", turret_visual, { player_index = index })
