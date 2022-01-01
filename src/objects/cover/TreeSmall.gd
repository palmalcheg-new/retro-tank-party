extends SGStaticBody2D

enum TreeColors {
	GREEN,
	BROWN,
}

const TREE_COLORS = {
	TreeColors.GREEN: Rect2(520, 694, 72, 72),
	TreeColors.BROWN: Rect2(592, 694, 72, 72),
}

export (TreeColors) var tree_color: int = TreeColors.GREEN setget set_tree_color

onready var sprite = $Sprite

func set_tree_color(color: int) -> void:
	if sprite == null:
		yield(self, "ready")
	sprite.region_rect = TREE_COLORS[color]

