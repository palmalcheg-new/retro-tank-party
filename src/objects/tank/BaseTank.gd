extends SGKinematicBody2D

const TANK_COLORS = {
	1: {
		body_sprite_region = Rect2( 434, 0, 84, 83 ),
		turret_sprite_region = Rect2( 722, 199, 24, 60 ),
	},
	2: {
		body_sprite_region = Rect2( 436, 308, 84, 80 ),
		turret_sprite_region = Rect2( 744, 684, 24, 60 ),
	},
	3: {
		body_sprite_region = Rect2( 520, 268, 76, 80 ),
		turret_sprite_region = Rect2( 724, 452, 24, 60 ),
	},
	4: {
		body_sprite_region = Rect2( 436, 692, 84, 80 ),
		turret_sprite_region = Rect2( 724, 512, 24, 60 ),
	},
}

onready var body_sprite := $BodySprite
onready var turret_sprite := $TurretPivot/TurretSprite
onready var turret_pivot := $TurretPivot
onready var bullet_start_position := $TurretPivot/BulletStartPosition
onready var collision_shape := $CollisionPolygon2D

func set_tank_color(index: int) -> void:
	body_sprite.region_rect = TANK_COLORS[index]['body_sprite_region']
	turret_sprite.region_rect = TANK_COLORS[index]['turret_sprite_region']
