extends Node2D
## Abandoned minecart full of faintly glowing ore (decoration).

const TEX := preload("res://assets/sprites/minecart.png")
const Ent := preload("res://scripts/entities.gd")


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	z_index = -2
	var s := Sprite2D.new()
	s.texture = TEX
	s.centered = false
	s.position = Vector2(-14, -26)
	add_child(s)
	var l := Ent.light(Color(1.0, 0.6, 0.3), 0.45, 0.6, 0.1, 0.5)
	l.position = Vector2(0, -22)
	add_child(l)
