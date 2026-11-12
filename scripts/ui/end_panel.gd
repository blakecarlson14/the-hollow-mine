extends CanvasLayer
## Results screen used for both "STAGE CLEAR" and "GAME OVER".
## Stat rows reveal one by one, then a Restart / Title menu appears.

signal restart_requested
signal quit_requested

const PixelText := preload("res://scripts/pixel_text.gd")
const MenuList := preload("res://scripts/ui/menu_list.gd")

var menu: Node2D


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## rows: Array of [label, value] pairs.
func present(title: String, title_color: Color, rows: Array, options: Array, bg: Color) -> void:
	visible = true
	var dim := ColorRect.new()
	dim.color = bg
	dim.size = Vector2(384, 216)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.5)

	var t := PixelText.new()
	t.text = title
	t.size = 3
	t.align = 1
	t.color = title_color
	t.position = Vector2(192, 28)
	t.modulate.a = 0.0
	add_child(t)
	tw.tween_property(t, "modulate:a", 1.0, 0.4)

	var y := 70
	for r in rows:
		var l := PixelText.new()
		l.text = r[0]
		l.position = Vector2(96, y)
		l.color = Color(0.7, 0.66, 0.82)
		l.modulate.a = 0.0
		add_child(l)
		var v := PixelText.new()
		v.text = r[1]
		v.align = 2
		v.position = Vector2(288, y)
		v.color = Color(1.0, 0.88, 0.62) if r.size() < 3 else r[2]
		v.modulate.a = 0.0
		add_child(v)
		tw.tween_interval(0.25)
		tw.tween_callback(Game.sfx.bind("select"))
		tw.tween_property(l, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(v, "modulate:a", 1.0, 0.12)
		y += 12
	menu = MenuList.new()
	menu.position = Vector2(192, maxi(y + 16, 160))
	menu.visible = false
	add_child(menu)
	menu.setup(options)
	menu.chosen.connect(_on_chosen)
	tw.tween_interval(0.3)
	tw.tween_callback(func(): menu.visible = true)


func _on_chosen(index: int) -> void:
	if index == 0:
		restart_requested.emit()
	else:
		quit_requested.emit()
