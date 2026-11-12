extends Node2D
## Keyboard/gamepad menu: a vertical list of pixel-text items with a blinking cursor.
## Works while the tree is paused (process mode ALWAYS).

signal chosen(index: int)

const PixelText := preload("res://scripts/pixel_text.gd")
const ICONS := preload("res://assets/ui/icons.png")

var selected := 0
var active := true
var spacing := 14
var labels: Array = []
var cursor: Sprite2D
var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(items: Array, item_spacing: int = 14) -> void:
	spacing = item_spacing
	for l in labels:
		l.queue_free()
	labels.clear()
	for i in items.size():
		var t := PixelText.new()
		t.text = items[i]
		t.align = 1
		t.position = Vector2(0, i * spacing)
		add_child(t)
		labels.append(t)
	if cursor == null:
		cursor = Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = ICONS
		at.region = Rect2(40, 0, 8, 8)
		cursor.texture = at
		cursor.centered = false
		add_child(cursor)
	selected = 0
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	if not active or not is_visible_in_tree() or labels.is_empty():
		return
	if Input.is_action_just_pressed("move_down"):
		selected = (selected + 1) % labels.size()
		Game.sfx("select")
	elif Input.is_action_just_pressed("move_up"):
		selected = (selected - 1 + labels.size()) % labels.size()
		Game.sfx("select")
	elif Input.is_action_just_pressed("accept"):
		Game.sfx("confirm")
		chosen.emit(selected)
	_refresh()


func _refresh() -> void:
	for i in labels.size():
		var t: Node2D = labels[i]
		if i == selected:
			var pulse := 0.5 + 0.5 * sin(_t * 6.0)
			t.color = Color(1.0, 0.72, 0.32).lerp(Color(1.0, 0.9, 0.62), pulse)
		else:
			t.color = Color(0.62, 0.58, 0.7)
	if cursor and selected < labels.size():
		var w := PixelText.text_width(labels[selected].text)
		cursor.position = Vector2(-w / 2 - 12 + int(sin(_t * 8.0) * 1.5), selected * spacing)
		cursor.modulate = Color(1.0, 0.85, 0.5)
