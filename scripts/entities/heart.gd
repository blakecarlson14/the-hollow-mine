extends Area2D
## Heart pickup: restores one heart (or +500 score at full health).

const TEX := preload("res://assets/sprites/heart.png")
const Fx := preload("res://scripts/fx.gd")
const Ent := preload("res://scripts/entities.gd")

var sprite: Sprite2D
var _t := 0.0


func setup(_args: Dictionary, _level: Node) -> void:
	pass


func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	monitorable = false
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 6.0
	cs.shape = sh
	add_child(cs)
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.modulate = Color(1.8, 1.5, 1.5)
	add_child(sprite)
	add_child(Ent.light(Color(1.0, 0.35, 0.3), 0.6, 0.5, 0.0))
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	var s := 1.0 + 0.12 * maxf(0.0, sin(_t * 6.0))
	sprite.scale = Vector2(s, s)
	sprite.position.y = roundf(sin(_t * 2.5) * 2.0)


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if Game.health < Game.MAX_HEALTH:
		Game.health += 1
		Fx.popup(global_position + Vector2(0, -10), "+1", Color(2.4, 0.9, 0.8))
	else:
		Game.add_score(500)
		Fx.popup(global_position + Vector2(0, -10), "500")
	Game.hud_changed.emit()
	Game.sfx("heart")
	Fx.sparkle(global_position, Color(2.5, 0.8, 0.7))
	queue_free()
