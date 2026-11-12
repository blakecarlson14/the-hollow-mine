extends RefCounted
## Entity factory used by the level builder. Every entity script exposes
## setup(args: Dictionary, level: Node) which is called before it enters the tree.

const DIR := "res://scripts/entities/%s.gd"


static func create(kind: String, pos: Vector2, args: Dictionary, level: Node) -> Node:
	var path := DIR % kind
	if not ResourceLoader.exists(path):
		push_error("No entity script for '%s'" % kind)
		return null
	var node: Node = load(path).new()
	node.position = pos
	if node.has_method("setup"):
		node.setup(args, level)
	return node


## Creates a PointLight2D with the retro banded falloff and optional flicker.
static func light(color: Color, energy: float, scale: float, flicker: float = 0.0, speed: float = 1.0) -> PointLight2D:
	var l: PointLight2D = preload("res://scripts/flicker_light.gd").new()
	l.texture = preload("res://assets/ui/light.png")
	l.color = color
	l.energy = energy
	l.base_energy = energy
	l.texture_scale = scale
	l.flicker = flicker
	l.speed = speed
	return l
