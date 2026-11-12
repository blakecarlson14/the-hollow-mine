extends Node2D
## Hanging oil lantern on a chain, with a flickering warm light.

const TEX := preload("res://assets/sprites/lantern.png")
const CHAIN := preload("res://assets/sprites/chain.png")
const Ent := preload("res://scripts/entities.gd")

var sprite: Sprite2D
var chain_len := 24.0
var _t := 0.0


func setup(args: Dictionary, level: Node) -> void:
	if args.has("chain"):
		chain_len = args["chain"]
	else:
		chain_len = level.ceiling_distance(position + Vector2(0, -7))


func _ready() -> void:
	z_index = -2
	var chain := Sprite2D.new()
	chain.texture = CHAIN
	chain.centered = false
	chain.region_enabled = true
	chain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	chain.region_rect = Rect2(0, 0, 4, chain_len)
	chain.position = Vector2(-2, -7 - chain_len)
	add_child(chain)
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.hframes = 3
	sprite.modulate = Color(1.7, 1.5, 1.3)
	add_child(sprite)
	var l := Ent.light(Color(1.0, 0.68, 0.35), 1.6, 2.4, 0.45, 1.0)
	l.position = Vector2(0, 2)
	add_child(l)
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * 7.0) % 3
	rotation = sin(_t * 1.3) * 0.03
