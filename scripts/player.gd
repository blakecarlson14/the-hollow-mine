extends CharacterBody2D
## Wick the miner. Platformer controller with coyote time, jump buffering, variable jump
## height, stomp detection (only from above), knockback, invulnerability and one-way drop-through.
## The node origin is at the player's feet.

signal died

const Fx := preload("res://scripts/fx.gd")

const RUN_SPEED := 115.0
const ACCEL := 950.0
const DECEL := 1300.0
const AIR_ACCEL := 750.0
const AIR_DECEL := 450.0
const GRAVITY := 900.0
const FALL_GRAVITY := 1150.0
const MAX_FALL := 330.0
const JUMP_VELOCITY := -315.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const STOMP_BOUNCE := -230.0
const STOMP_BOUNCE_HELD := -335.0
const INVULN_TIME := 1.5
const HURT_TIME := 0.35
const HIT_SIZE := Vector2(8, 18)

enum State { NORMAL, HURT, DEAD, AUTO, FROZEN }

var state := State.NORMAL
var facing := 1
var coyote := 0.0
var jump_buffer := 0.0
var invuln := 0.0
var hurt_timer := 0.0
var drop_timer := 0.0
var anim_time := 0.0
var stomp_chain := 0
var was_on_floor := true
var jumping := false
var dead_timer := 0.0
var dead_vel := Vector2.ZERO
var shake := 0.0
var last_frame := 0
var kill_y := 100000.0

@onready var sprite: Sprite2D = $Sprite
@onready var lamp: PointLight2D = $Lamp
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		_dead_process(delta)
		return
	if state == State.FROZEN:
		velocity = Vector2.ZERO
		_animate(delta)
		return

	invuln = maxf(invuln - delta, 0.0)
	if drop_timer > 0.0:
		drop_timer -= delta
		if drop_timer <= 0.0:
			set_collision_mask_value(2, true)

	var input_x := 0.0
	if state == State.NORMAL:
		input_x = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			jump_buffer = JUMP_BUFFER
	elif state == State.AUTO:
		input_x = 0.55
	elif state == State.HURT:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			state = State.NORMAL

	coyote = COYOTE_TIME if is_on_floor() else maxf(coyote - delta, 0.0)
	jump_buffer = maxf(jump_buffer - delta, 0.0)

	# horizontal
	var target := input_x * RUN_SPEED
	var rate: float
	if is_on_floor():
		rate = ACCEL if absf(target) > 0.01 else DECEL
	else:
		rate = AIR_ACCEL if absf(target) > 0.01 else AIR_DECEL
	if state == State.HURT:
		rate = 180.0
	velocity.x = move_toward(velocity.x, target, rate * delta)
	if absf(input_x) > 0.1 and state != State.HURT:
		facing = 1 if input_x > 0.0 else -1

	# vertical
	var g := GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)

	if jump_buffer > 0.0 and coyote > 0.0 and state == State.NORMAL:
		jump_buffer = 0.0
		if Input.is_action_pressed("move_down") and _standing_on_oneway():
			set_collision_mask_value(2, false)
			drop_timer = 0.22
			position.y += 2.0
			coyote = 0.0
		else:
			velocity.y = JUMP_VELOCITY
			jumping = true
			coyote = 0.0
			Game.sfx("jump")
			Fx.dust(global_position, 3)
	if jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump") and state == State.NORMAL:
		velocity.y *= JUMP_CUT
		jumping = false
	if velocity.y >= 0.0:
		jumping = false

	var prev_feet := global_position.y
	var pre_vy := velocity.y
	move_and_slide()

	if is_on_floor():
		if not was_on_floor:
			stomp_chain = 0
			if pre_vy > 160.0:
				Fx.dust(global_position, 6)
				Game.sfx("land", -6.0)
	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0
	was_on_floor = is_on_floor()

	_check_hits(prev_feet, pre_vy, delta)
	if global_position.y > kill_y:
		die(true)
	_animate(delta)


func _process(delta: float) -> void:
	if shake > 0.0:
		shake = maxf(shake - delta * 18.0, 0.0)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)).round()
	else:
		camera.offset = Vector2.ZERO
	lamp.position.x = 5.0 * facing
	lamp.energy = 1.5 + 0.06 * sin(Time.get_ticks_msec() * 0.011)


func _standing_on_oneway() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < -0.5:
			var layer := PhysicsServer2D.body_get_collision_layer(c.get_collider_rid())
			if layer & 1:
				return false
			if layer & 2:
				return true
	return false


func hit_rect() -> Rect2:
	return Rect2(global_position - Vector2(HIT_SIZE.x * 0.5, HIT_SIZE.y), HIT_SIZE)


func _check_hits(prev_feet: float, pre_vy: float, delta: float) -> void:
	if state == State.DEAD or state == State.AUTO:
		return
	var r := hit_rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_alive():
			continue
		var er: Rect2 = e.hit_rect()
		if not r.intersects(er):
			continue
		var tol := 4.0 + maxf(pre_vy, 0.0) * delta
		if pre_vy > 0.0 and prev_feet <= er.position.y + tol:
			stomp_chain += 1
			var pts := mini(100 * int(pow(2, stomp_chain - 1)), 1600)
			e.stomp()
			Game.add_score(pts)
			Game.stomps += 1
			Fx.popup(er.get_center() + Vector2(0, -10), str(pts))
			velocity.y = STOMP_BOUNCE_HELD if Input.is_action_pressed("jump") else STOMP_BOUNCE
			jumping = true
			shake = 2.0
		else:
			take_damage(e.global_position.x)
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.has_method("is_active") and not h.is_active():
			continue
		if r.intersects(h.hit_rect()):
			take_damage(h.global_position.x, true)


func take_damage(from_x: float, upward: bool = false) -> void:
	if invuln > 0.0 or state == State.DEAD or state == State.AUTO or state == State.FROZEN:
		return
	Game.health -= 1
	Game.hud_changed.emit()
	shake = 4.0
	if Game.health <= 0:
		die(false)
		return
	Game.sfx("hurt")
	state = State.HURT
	hurt_timer = HURT_TIME
	invuln = INVULN_TIME
	jumping = false
	var dir := signf(global_position.x - from_x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * 150.0, -260.0 if upward else -190.0)


func die(pit: bool) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	Game.health = 0
	Game.hud_changed.emit()
	Game.sfx("die")
	velocity = Vector2.ZERO
	dead_timer = 1.6
	sprite.frame = 11
	sprite.visible = true
	shake = 5.0
	if pit:
		dead_vel = Vector2.ZERO
		sprite.visible = false
	else:
		dead_vel = Vector2(0, -230)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)


func _dead_process(delta: float) -> void:
	if sprite.visible:
		sprite.position += dead_vel * delta
		dead_vel.y += 700.0 * delta
	dead_timer -= delta
	if dead_timer <= 0.0 and dead_timer > -100.0:
		dead_timer = -1000.0
		died.emit()


func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	state = State.NORMAL
	sprite.position = Vector2.ZERO
	sprite.visible = true
	facing = 1
	invuln = 1.0
	jumping = false
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	reset_physics_interpolation()
	camera.reset_smoothing()


func start_auto_walk() -> void:
	state = State.AUTO
	invuln = 0.0


func freeze() -> void:
	state = State.FROZEN


func _animate(delta: float) -> void:
	var frame := 0
	if state == State.DEAD:
		frame = 11
	elif state == State.HURT:
		frame = 10
	elif not is_on_floor():
		frame = 8 if velocity.y < 0.0 else 9
	elif absf(velocity.x) > 8.0:
		anim_time += delta * maxf(absf(velocity.x) / RUN_SPEED, 0.4) * 12.0
		frame = 2 + int(anim_time) % 6
		if frame != last_frame and (frame == 3 or frame == 6):
			Fx.dust(global_position + Vector2(-4 * facing, 0), 2)
	else:
		anim_time += delta * 2.0
		frame = int(anim_time) % 2
	last_frame = frame
	sprite.frame = frame
	sprite.flip_h = facing < 0
	if state == State.AUTO:
		return
	if invuln > 0.0 and state != State.DEAD:
		sprite.modulate.a = 0.25 if int(invuln * 16.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
