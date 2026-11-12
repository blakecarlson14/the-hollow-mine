extends CanvasLayer
## Pause menu (Esc / P / Start): Resume, Restart Stage, Quit to Title.

signal restart_requested
signal quit_requested

const PixelText := preload("res://scripts/pixel_text.gd")
const MenuList := preload("res://scripts/ui/menu_list.gd")

var enabled := true
var menu: Node2D
var _opened_frame := -1


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.72)
	dim.size = Vector2(384, 216)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var title := PixelText.new()
	title.text = "PAUSED"
	title.size = 3
	title.align = 1
	title.color = Color(1.0, 0.8, 0.5)
	title.position = Vector2(192, 46)
	add_child(title)
	menu = MenuList.new()
	menu.position = Vector2(192, 98)
	add_child(menu)
	menu.setup(["RESUME", "RESTART STAGE", "QUIT TO TITLE"])
	menu.chosen.connect(_on_chosen)
	var help := PixelText.new()
	help.text = "MOVE: ARROWS/WASD   JUMP: SPACE/Z/UP\nDOWN+JUMP: DROP THROUGH PLANKS"
	help.align = 1
	help.color = Color(0.55, 0.52, 0.65)
	help.position = Vector2(192, 172)
	add_child(help)


func _process(_delta: float) -> void:
	if not enabled:
		return
	if Input.is_action_just_pressed("pause") and Engine.get_process_frames() != _opened_frame:
		if visible:
			close()
		else:
			open()


func open() -> void:
	visible = true
	_opened_frame = Engine.get_process_frames()
	menu.selected = 0
	get_tree().paused = true
	Game.sfx("select")


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_chosen(index: int) -> void:
	match index:
		0:
			close()
		1:
			restart_requested.emit()
		2:
			quit_requested.emit()
