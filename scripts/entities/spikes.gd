extends Node2D
## Rusted iron floor spikes (one tile wide). Touching them costs a heart and bounces you up.

const TEX := preload("res://assets/sprites/spikes.png")


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	add_to_group("hazards")
	z_index = 1
	var s := Sprite2D.new()
	s.texture = TEX
	s.centered = false
	s.position = Vector2(-8, -8)
	add_child(s)


func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-7, -6), Vector2(14, 6))
