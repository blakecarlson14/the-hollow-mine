extends Node2D
## Glowing crystal cluster growing from the floor (variants 0-1 cyan, 2 violet).

const TEX := preload("res://assets/sprites/crystal.png")
const SPARK := preload("res://assets/ui/spark.png")
const Ent := preload("res://scripts/entities.gd")

var variant := 0
var sprite: Sprite2D
var glow: PointLight2D
var _t := 0.0


func setup(args: Dictionary, _level: Node) -> void:
	variant = int(args.get("variant", 0))


func _ready() -> void:
	z_index = -1
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.hframes = 3
	sprite.frame = variant
	sprite.position = Vector2(0, -8)
	add_child(sprite)
	var col := Color(0.4, 0.85, 1.0) if variant != 2 else Color(0.75, 0.45, 1.0)
	glow = Ent.light(col, 0.7, 1.6, 0.0)
	glow.position = Vector2(0, -8)
	add_child(glow)
	var sp := CPUParticles2D.new()
	sp.texture = SPARK
	sp.amount = 3
	sp.lifetime = 1.6
	sp.position = Vector2(0, -8)
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(6, 6)
	sp.gravity = Vector2(0, -6)
	sp.initial_velocity_max = 3.0
	sp.scale_amount_min = 0.3
	sp.scale_amount_max = 0.7
	var g := Gradient.new()
	g.set_color(0, Color(col.r * 2.5, col.g * 2.5, col.b * 2.5, 1.0))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	sp.color_ramp = g
	add_child(sp)
	_t = position.x * 0.1


func _process(delta: float) -> void:
	_t += delta
	var p := 0.5 + 0.5 * sin(_t * 1.7)
	sprite.modulate = Color(1.05, 1.05, 1.1).lerp(Color(1.45, 1.45, 1.55), p)
	glow.base_energy = 0.6 + 0.25 * p
