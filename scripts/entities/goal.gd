extends Area2D
## The mine exit: a timber gate full of daylight. Entering it clears the stage.

const TEX := preload("res://assets/sprites/goal.png")
const Ent := preload("res://scripts/entities.gd")

var triggered := false


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	monitorable = false
	z_index = -3
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(20, 60)
	cs.shape = sh
	cs.position = Vector2(4, -30)
	add_child(cs)
	var s := Sprite2D.new()
	s.texture = TEX
	s.centered = false
	s.position = Vector2(-32, -80)
	s.modulate = Color(1.0, 1.0, 1.0)
	add_child(s)
	var inner := Sprite2D.new()
	inner.texture = TEX
	inner.centered = false
	inner.region_enabled = true
	inner.region_rect = Rect2(10, 9, 44, 71)
	inner.position = Vector2(-22, -71)
	inner.modulate = Color(2.4, 2.2, 1.9)
	add_child(inner)
	var l := Ent.light(Color(1.0, 0.9, 0.7), 1.6, 3.5, 0.0)
	l.position = Vector2(0, -40)
	add_child(l)
	var motes := CPUParticles2D.new()
	motes.texture = preload("res://assets/ui/dot.png")
	motes.amount = 24
	motes.lifetime = 3.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(20, 34)
	motes.position = Vector2(0, -38)
	motes.direction = Vector2(-1, 0)
	motes.spread = 30.0
	motes.gravity = Vector2(0, -4)
	motes.initial_velocity_min = 4.0
	motes.initial_velocity_max = 12.0
	motes.scale_amount_min = 0.5
	motes.scale_amount_max = 1.0
	motes.color = Color(3.0, 2.6, 1.8, 0.8)
	add_child(motes)
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	var game := get_tree().current_scene
	if game.has_method("stage_clear"):
		game.stage_clear()
