extends RefCounted
## One-shot visual effects: particle bursts and floating score text.

const DOT := preload("res://assets/ui/dot.png")
const SPARK := preload("res://assets/ui/spark.png")
const ROCKBITS := preload("res://assets/sprites/rockbits.png")
const PixelText := preload("res://scripts/pixel_text.gd")


static func _root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree else null


static func burst(pos: Vector2, color: Color, amount: int = 8, speed: float = 60.0, gravity: float = 200.0,
		lifetime: float = 0.5, spread: float = 180.0, dir: Vector2 = Vector2.UP, tex: Texture2D = DOT) -> CPUParticles2D:
	var root := _root()
	if root == null:
		return null
	var p := CPUParticles2D.new()
	p.texture = tex
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var grad := Gradient.new()
	grad.set_color(0, color)
	var end := color
	end.a = 0.0
	grad.set_color(1, end)
	p.color_ramp = grad
	p.position = pos
	p.z_index = 5
	root.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func dust(pos: Vector2, amount: int = 5) -> void:
	burst(pos, Color(0.75, 0.7, 0.8, 0.8), amount, 28.0, -10.0, 0.45, 70.0, Vector2.UP)


static func stomp_puff(pos: Vector2) -> void:
	burst(pos, Color(0.9, 0.85, 1.0, 0.9), 12, 70.0, 60.0, 0.4, 180.0)
	burst(pos, Color(2.2, 1.4, 0.6, 1.0), 6, 90.0, 120.0, 0.35, 60.0, Vector2.UP, SPARK)


static func rock_shatter(pos: Vector2) -> void:
	var p := burst(pos, Color(0.9, 0.9, 1.0, 1.0), 10, 90.0, 400.0, 0.7, 70.0, Vector2.UP, ROCKBITS)
	if p:
		p.scale_amount_min = 0.8
		p.scale_amount_max = 1.0
	dust(pos, 6)


static func sparkle(pos: Vector2, color: Color) -> void:
	burst(pos, color, 8, 50.0, 0.0, 0.4, 180.0, Vector2.UP, SPARK)


static func popup(pos: Vector2, text: String, color: Color = Color(2.0, 1.7, 1.0)) -> void:
	var root := _root()
	if root == null:
		return
	var t := PixelText.new()
	t.text = text
	t.color = color
	t.align = 1
	t.position = pos
	t.z_index = 20
	root.add_child(t)
	var tw := t.create_tween()
	tw.tween_property(t, "position:y", pos.y - 18.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(t, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.tween_callback(t.queue_free)
