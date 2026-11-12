extends "res://scripts/entities/enemy_base.gd"
## Gloomwing: a moth-like flyer with a glowing abdomen. It hovers near its roost and
## swoops down at the player when they pass beneath, then flutters back up.

const TEX := preload("res://assets/sprites/swooper.png")

enum S { HOVER, WINDUP, DIVE, RETURN, FALL }

var state := S.HOVER
var home := Vector2.ZERO
var target := Vector2.ZERO
var dive_dir := Vector2.ZERO
var timer := 0.0
var cooldown := 1.0
var glow: PointLight2D
var _t := 0.0


func setup(args: Dictionary, lvl: Node) -> void:
	super.setup(args, lvl)
	home = position


func _build() -> void:
	collision_mask = 0
	hit_size = Vector2(14, 9)
	hit_offset = Vector2(0, 1)
	sprite = make_sprite(TEX, 5, Vector2.ZERO)
	sprite.modulate = Color(1.3, 1.3, 1.3)
	glow = Ent.light(Color(0.7, 1.0, 0.45), 0.85, 0.9, 0.15, 1.5)
	glow.position = Vector2(0, 2)
	add_child(glow)
	_t = randf() * 6.0


func _physics_process(delta: float) -> void:
	_t += delta
	if state == S.FALL:
		velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
		position += velocity * delta
		return
	if not near_player():
		return
	cooldown = maxf(cooldown - delta, 0.0)
	var flap: int = [0, 1, 2, 1][int(_t * 10.0) % 4]
	match state:
		S.HOVER:
			var want := home + Vector2(sin(_t * 0.9) * 22.0, sin(_t * 2.3) * 5.0)
			position = position.lerp(want, minf(1.0, delta * 3.0))
			sprite.frame = flap
			var to_p := player.global_position + Vector2(0, -10) - global_position
			if cooldown <= 0.0 and to_p.y > 24.0 and to_p.y < 170.0 and absf(to_p.x) < 120.0:
				state = S.WINDUP
				timer = 0.4
				facing = 1 if to_p.x > 0 else -1
				Game.sfx("swoop", -4.0)
		S.WINDUP:
			timer -= delta
			position.y -= 18.0 * delta
			sprite.frame = [0, 2][int(_t * 24.0) % 2]
			if timer <= 0.0:
				target = player.global_position + Vector2(0, -10)
				dive_dir = (target - global_position).normalized()
				state = S.DIVE
				timer = 1.1
		S.DIVE:
			timer -= delta
			sprite.frame = 3
			velocity = dive_dir * 150.0
			position += velocity * delta
			var passed := (target - global_position).dot(dive_dir) < 0.0
			if passed or timer <= 0.0 or (level and level.is_solid_px(global_position + dive_dir * 8.0)):
				state = S.RETURN
		S.RETURN:
			sprite.frame = flap
			position = position.move_toward(home, 60.0 * delta)
			if position.distance_to(home) < 2.0:
				state = S.HOVER
				cooldown = 1.3
	if state != S.DIVE:
		facing = 1 if (player.global_position.x > global_position.x) else -1
	sprite.flip_h = facing < 0


func stomp() -> void:
	if not alive:
		return
	super.stomp()
	set_physics_process(true)
	state = S.FALL
	velocity = Vector2(0, -40)


func _on_stomped() -> void:
	sprite.frame = 4
	glow.visible = false
