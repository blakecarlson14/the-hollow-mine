extends CharacterBody2D
## Shared enemy behaviour. Origin is at the enemy's feet (swooper: body centre).
## The player script decides stomp vs. hurt using hit_rect(): only a falling player whose
## feet were above the rect's top on the previous frame stomps; any other contact hurts.

const Fx := preload("res://scripts/fx.gd")
const Ent := preload("res://scripts/entities.gd")
const GRAVITY := 900.0
const ACTIVE_RANGE := 420.0

var alive := true
var hit_size := Vector2(12, 10)
var hit_offset := Vector2(0, -5)
var sprite: Sprite2D
var facing := -1
var level: Node
var player: Node2D


func setup(_args: Dictionary, lvl: Node) -> void:
	level = lvl


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 3
	floor_snap_length = 4.0
	z_index = 1
	_build()


## Override: create sprite, shapes and lights.
func _build() -> void:
	pass


func is_alive() -> bool:
	return alive


func hit_rect() -> Rect2:
	return Rect2(global_position + hit_offset - hit_size * 0.5, hit_size)


func near_player() -> bool:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	return player != null and absf(player.global_position.x - global_position.x) < ACTIVE_RANGE


func add_shape(size: Vector2, offset: Vector2) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = offset
	add_child(cs)


func make_sprite(tex: Texture2D, frames: int, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = frames
	s.offset = offset
	add_child(s)
	return s


func stomp() -> void:
	if not alive:
		return
	alive = false
	remove_from_group("enemies")
	Game.sfx("stomp")
	Fx.stomp_puff(global_position + hit_offset)
	_on_stomped()
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


## Override for the squashed look.
func _on_stomped() -> void:
	pass
