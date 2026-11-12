extends "res://scripts/entities/enemy_base.gd"
## Rustback: a slow dome-shelled crawler that patrols, turning at walls and ledges.

const TEX := preload("res://assets/sprites/crawler.png")
const SPEED := 28.0

var ledge_ray: RayCast2D
var eye: PointLight2D
var _anim := 0.0


func _build() -> void:
	hit_size = Vector2(13, 9)
	hit_offset = Vector2(0, -5)
	add_shape(Vector2(12, 9), Vector2(0, -4.5))
	sprite = make_sprite(TEX, 5, Vector2(0, -6))
	ledge_ray = RayCast2D.new()
	ledge_ray.collision_mask = 3
	ledge_ray.target_position = Vector2(0, 10)
	add_child(ledge_ray)
	eye = Ent.light(Color(1.0, 0.35, 0.2), 0.55, 0.35, 0.2, 2.0)
	eye.position = Vector2(5, -5)
	add_child(eye)


func _physics_process(delta: float) -> void:
	if not near_player():
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
	velocity.x = SPEED * facing
	ledge_ray.position = Vector2(8 * facing, -2)
	ledge_ray.force_raycast_update()
	if is_on_floor() and not ledge_ray.is_colliding():
		facing = -facing
	move_and_slide()
	if is_on_wall():
		facing = -facing
	_anim += delta * 8.0
	sprite.frame = int(_anim) % 4
	sprite.flip_h = facing < 0
	eye.position.x = 5 * facing


func _on_stomped() -> void:
	sprite.frame = 4
	eye.visible = false
