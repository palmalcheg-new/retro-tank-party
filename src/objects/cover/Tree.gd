extends SGStaticBody2D

enum TreeColors {
	GREEN,
	BROWN,
}

const COLOR_NAMES = {
	TreeColors.GREEN: "green",
	TreeColors.BROWN: "brown",
}

export (String) var visual_id := ""
export (TreeColors) var tree_color: int = TreeColors.GREEN setget set_tree_color

onready var visual = $Visual

func _ready() -> void:
	visual = Globals.art.replace_visual(visual_id, visual, {
		color = COLOR_NAMES[tree_color]
	})

func set_tree_color(color: int) -> void:
	if color != tree_color:
		tree_color = color
		if visual == null:
			yield(self, "ready")
		visual = Globals.art.replace_visual(visual_id, visual, {
			color = COLOR_NAMES[tree_color]
		})
