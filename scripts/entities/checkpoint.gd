extends Area2D
## Spirit-lantern checkpoint. Touch it to light it: sets the respawn point and refills health.

const TEX := preload("res://assets/sprites/checkpoint.png")
const Fx := preload("res://scripts/fx.gd")
const Ent := preload("res://scripts/entities.gd")

var sprite: Sprite2D
var glow: PointLight2D
var lit := false


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	add_to_group("checkpoints")
	collision_layer = 16
	collision_mask = 4
	monitorable = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(20, 32)
	cs.shape = sh
	cs.position = Vector2(0, -16)
	add_child(cs)
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.hframes = 2
	sprite.position = Vector2(0, -16)
	add_child(sprite)
	glow = Ent.light(Color(0.45, 0.85, 1.0), 0.0, 1.2, 0.15, 0.6)
	glow.position = Vector2(4, -22)
	add_child(glow)
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if lit or not body.is_in_group("player"):
		return
	lit = true
	sprite.frame = 1
	sprite.modulate = Color(1.6, 1.6, 1.8)
	var tw := create_tween()
	tw.tween_property(glow, "base_energy", 1.4, 0.4)
	Game.checkpoint_pos = global_position
	Game.health = Game.MAX_HEALTH
	Game.hud_changed.emit()
	Game.sfx("checkpoint")
	Fx.sparkle(global_position + Vector2(4, -22), Color(1.2, 2.2, 3.0))
	Fx.popup(global_position + Vector2(0, -40), "CHECKPOINT", Color(1.4, 2.2, 2.8))
