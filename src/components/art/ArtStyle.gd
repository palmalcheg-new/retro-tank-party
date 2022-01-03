extends Resource
class_name ArtStyle

export (String) var name := ""
export (String, DIR) var texture_base_path := ""
export (Script) var art_script: Script = preload("res://src/components/art/BaseArt.gd")
export (Texture) var cursor_texture: Texture = preload("res://assets/cursor.png")
