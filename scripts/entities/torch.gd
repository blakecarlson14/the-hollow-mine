extends Node2D
## Wall torch with a strongly flickering light and rising embers.

const TEX := preload("res://assets/sprites/torch.png")
const SPARK := preload("res://assets/ui/spark.png")
const Ent := preload("res://scripts/entities.gd")

var sprite: Sprite2D
var _t := 0.0


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	z_index = -2
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.hframes = 3
	sprite.modulate = Color(1.8, 1.5, 1.2)
	add_child(sprite)
	var l := Ent.light(Color(1.0, 0.55, 0.25), 2.3, 2.4, 0.5, 1.4)
	l.position = Vector2(0, -6)
	add_child(l)
	var embers := CPUParticles2D.new()
	embers.texture = SPARK
	embers.amount = 6
	embers.lifetime = 1.4
	embers.position = Vector2(0, -7)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(2, 1)
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 8.0
	embers.initial_velocity_max = 20.0
	embers.scale_amount_min = 0.25
	embers.scale_amount_max = 0.6
	var g := Gradient.new()
	g.set_color(0, Color(4.0, 2.2, 0.8, 1.0))
	g.set_color(1, Color(2.0, 0.6, 0.2, 0.0))
	embers.color_ramp = g
	add_child(embers)
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * 10.0) % 3
