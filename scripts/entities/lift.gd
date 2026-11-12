extends AnimatableBody2D
## Chain-hung wooden lift that eases back and forth between two points (one-way platform).
## Position = centre of the plank's top surface.

const TEX := preload("res://assets/sprites/lift.png")
const CHAIN := preload("res://assets/sprites/chain.png")
const DWELL := 0.16

var from := Vector2.ZERO
var to := Vector2.ZERO
var period := 4.0
var level: Node
var chains: Array[Sprite2D] = []
var _t := 0.0


func setup(args: Dictionary, lvl: Node) -> void:
	level = lvl
	from = position
	if args.has("to_px"):
		to = args["to_px"]
	else:
		var c: Vector2 = args.get("to", Vector2(position.x / 16.0, position.y / 16.0))
		to = Vector2(c.x * 16.0 + 8.0, c.y * 16.0)
	period = float(args.get("period", 4.0))


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 2
	collision_mask = 0
	z_index = -1
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 6)
	cs.shape = sh
	cs.position = Vector2(0, 3)
	cs.one_way_collision = true
	add_child(cs)
	for x in [-20.0, 20.0]:
		var ch := Sprite2D.new()
		ch.texture = CHAIN
		ch.centered = false
		ch.region_enabled = true
		ch.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ch.position = Vector2(x - 2.0, 0)
		add_child(ch)
		chains.append(ch)
	var s := Sprite2D.new()
	s.texture = TEX
	s.centered = false
	s.position = Vector2(-24, -2)
	add_child(s)
	_update_chains()


func _physics_process(delta: float) -> void:
	_t += delta
	# trapezoid motion: dwell at each end, eased travel in between
	var u := fposmod(_t / period, 1.0)
	var s := 0.0
	if u < DWELL:
		s = 0.0
	elif u < 0.5:
		s = smoothstep(0.0, 1.0, (u - DWELL) / (0.5 - DWELL))
	elif u < 0.5 + DWELL:
		s = 1.0
	else:
		s = 1.0 - smoothstep(0.0, 1.0, (u - 0.5 - DWELL) / (0.5 - DWELL))
	position = from.lerp(to, s).round()
	_update_chains()


func _update_chains() -> void:
	if level == null:
		return
	for ch in chains:
		var top_y: float = level.ceiling_distance(global_position + Vector2(ch.position.x + 2.0, -1.0))
		top_y = minf(top_y, 600.0)
		ch.region_rect = Rect2(0, 0, 4, top_y)
		ch.position.y = -top_y
