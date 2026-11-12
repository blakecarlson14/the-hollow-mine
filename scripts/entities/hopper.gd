extends "res://scripts/entities/enemy_base.gd"
## Shalehop: a crystal-backed slate creature that crouches and hops toward the player,
## refusing to leap into pits.

const TEX := preload("res://assets/sprites/hopper.png")
const HOP_X := 60.0
const HOP_Y := -250.0

enum S { IDLE, CROUCH, AIR }

var state := S.IDLE
var timer := 1.0
var glow: PointLight2D


func _build() -> void:
	hit_size = Vector2(13, 10)
	hit_offset = Vector2(0, -6)
	add_shape(Vector2(12, 10), Vector2(0, -5))
	sprite = make_sprite(TEX, 5, Vector2(0, -8))
	glow = Ent.light(Color(0.45, 0.8, 1.0), 0.5, 0.6, 0.0)
	glow.position = Vector2(-2, -12)
	add_child(glow)
	timer = randf_range(0.6, 1.6)


func _physics_process(delta: float) -> void:
	if not near_player():
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	match state:
		S.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			sprite.frame = 0
			timer -= delta
			if timer <= 0.0 and is_on_floor():
				state = S.CROUCH
				timer = 0.28
		S.CROUCH:
			velocity.x = 0.0
			sprite.frame = 1
			timer -= delta
			if timer <= 0.0:
				_hop()
		S.AIR:
			sprite.frame = 2 if velocity.y < 0.0 else 3
			if is_on_floor() and velocity.y >= 0.0:
				state = S.IDLE
				timer = randf_range(0.9, 1.6)
				velocity.x = 0.0
				Fx.dust(global_position, 3)
	move_and_slide()
	if is_on_wall() and state == S.AIR:
		velocity.x = -velocity.x * 0.5
	sprite.flip_h = facing < 0
	hit_size.y = 8.0 if sprite.frame == 1 else 10.0


func _hop() -> void:
	var dir := facing
	if player and absf(player.global_position.x - global_position.x) < 180.0:
		dir = 1 if player.global_position.x > global_position.x else -1
	facing = dir
	var vx := HOP_X * dir
	# don't jump into a pit: check for floor where we would land
	var land := global_position + Vector2(dir * 40.0, -4.0)
	if not level.floor_below(land, 4):
		facing = -dir
		vx = 0.0
	velocity = Vector2(vx, HOP_Y)
	state = S.AIR


func _on_stomped() -> void:
	sprite.frame = 4
	glow.visible = false
