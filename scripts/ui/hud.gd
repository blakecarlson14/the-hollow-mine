extends CanvasLayer
## In-game HUD: hearts, lives, gems, score and timer, plus a stage-title banner.

const PixelText := preload("res://scripts/pixel_text.gd")
const ICONS := preload("res://assets/ui/icons.png")

var hearts: Array[Sprite2D] = []
var lives_text: Node2D
var gems_text: Node2D
var score_text: Node2D
var time_text: Node2D
var banner: Node2D
var banner_sub: Node2D


func _ready() -> void:
	layer = 10
	var bar := ColorRect.new()
	bar.color = Color(0.0, 0.0, 0.02, 0.45)
	bar.size = Vector2(384, 20)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var edge := ColorRect.new()
	edge.color = Color(0.35, 0.28, 0.45, 0.5)
	edge.position = Vector2(0, 20)
	edge.size = Vector2(384, 1)
	add_child(edge)
	for i in Game.MAX_HEALTH:
		var s := _icon(0, Vector2(6 + i * 10, 6))
		hearts.append(s)
	_icon(2, Vector2(42, 6))
	lives_text = _text(Vector2(52, 7), "X3")
	_icon(3, Vector2(150, 6))
	gems_text = _text(Vector2(161, 7), "0/0")
	score_text = _text(Vector2(378, 7), "000000", 2)
	score_text.color = Color(1.0, 0.9, 0.7)
	_text(Vector2(300, 7), "SCORE").color = Color(0.6, 0.55, 0.7)
	_icon(4, Vector2(326, 23))
	time_text = _text(Vector2(378, 24), "0:00.00", 2)
	time_text.color = Color(0.75, 0.72, 0.85)
	banner = _text(Vector2(192, 82), "", 1)
	banner.size = 2
	banner_sub = _text(Vector2(192, 104), "", 1)
	Game.hud_changed.connect(refresh)
	refresh()


func _icon(index: int, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = ICONS
	at.region = Rect2(index * 8, 0, 8, 8)
	s.texture = at
	s.centered = false
	s.position = pos
	add_child(s)
	return s


func _text(pos: Vector2, t: String, align: int = 0) -> Node2D:
	var n := PixelText.new()
	n.text = t
	n.align = align
	n.position = pos
	add_child(n)
	return n


func refresh() -> void:
	for i in hearts.size():
		var at: AtlasTexture = hearts[i].texture
		at.region = Rect2(0 if i < Game.health else 8, 0, 8, 8)
	lives_text.text = "X%d" % maxi(Game.lives, 0)
	gems_text.text = "%d/%d" % [Game.gems, Game.gems_total]
	score_text.text = "%06d" % Game.score


func _process(_delta: float) -> void:
	time_text.text = Game.format_time(Game.time)
	if Game.health == 1:
		hearts[0].modulate = Color(1, 1, 1, 1.0 if int(Time.get_ticks_msec() / 250.0) % 2 == 0 else 0.4)
	else:
		hearts[0].modulate = Color.WHITE


func show_banner(title: String, sub: String) -> void:
	banner.text = title
	banner_sub.text = sub
	banner.color = Color(1.0, 0.8, 0.45)
	banner_sub.color = Color(0.8, 0.75, 0.95)
	for n in [banner, banner_sub]:
		n.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(n, "modulate:a", 1.0, 0.6)
		tw.tween_interval(1.8)
		tw.tween_property(n, "modulate:a", 0.0, 0.8)
