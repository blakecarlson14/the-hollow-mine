extends Node2D
## Falling stalactite. Hangs from the ceiling, shakes when the player passes underneath,
## drops, shatters on the floor and slowly regrows. Only dangerous while falling.

const TEX := preload("res://assets/sprites/stalactite.png")
const Fx := preload("res://scripts/fx.gd")

enum S { HANG, SHAKE, FALL, GONE }

var state := S.HANG
var level: Node
var home := Vector2.ZERO
var vel := 0.0
var timer := 0.0
var sprite: Sprite2D


func setup(_args: Dictionary, lvl: Node) -> void:
	level = lvl
	home = position


func _ready() -> void:
	add_to_group("hazards")
	z_index = 1
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.centered = false
	sprite.position = Vector2(-6, 0)
	add_child(sprite)


func is_active() -> bool:
	return state == S.FALL


func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-4, 4), Vector2(8, 13))


func _physics_process(delta: float) -> void:
	match state:
		S.HANG:
			var p := get_tree().get_first_node_in_group("player") as Node2D
			if p:
				var d := p.global_position - global_position
				if absf(d.x) < 34.0 and d.y > 0.0 and d.y < 200.0:
					state = S.SHAKE
					timer = 0.45
					Game.sfx("rock", -14.0, 1.6)
		S.SHAKE:
			timer -= delta
			sprite.position.x = -6 + (1 if int(timer * 40.0) % 2 == 0 else -1)
			if timer <= 0.0:
				sprite.position.x = -6
				state = S.FALL
				vel = 0.0
		S.FALL:
			vel = minf(vel + 900.0 * delta, 420.0)
			position.y += vel * delta
			var tip := global_position + Vector2(0, 17)
			if level.floor_at(tip) or position.y > level.size_px.y + 40.0:
				_shatter()
		S.GONE:
			timer -= delta
			if timer <= 0.0:
				position = home
				reset_physics_interpolation()
				state = S.HANG
				sprite.visible = true
				sprite.modulate.a = 0.0
				create_tween().tween_property(sprite, "modulate:a", 1.0, 0.8)


func _shatter() -> void:
	state = S.GONE
	timer = 3.5
	sprite.visible = false
	Fx.rock_shatter(global_position + Vector2(0, 14))
	Game.sfx("rock", -4.0)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position) < 140.0:
		p.shake = 3.0
