extends Area2D
## Ember-ore gem pickup (+50 score).

const TEX := preload("res://assets/sprites/gem.png")
const Fx := preload("res://scripts/fx.gd")

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
	sprite.hframes = 4
	sprite.modulate = Color(1.9, 1.6, 1.2)
	add_child(sprite)
	_t = position.x * 0.05
	body_entered.connect(_on_body)
	Game.gems_total += 1


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * 8.0) % 4
	sprite.position.y = roundf(sin(_t * 3.0) * 1.5)


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	Game.gems += 1
	Game.add_score(50)
	Game.sfx("gem", -3.0)
	Fx.sparkle(global_position, Color(2.6, 1.8, 0.7))
	queue_free()
