extends Node2D
## Title screen: slowly drifting parallax cavern, Wick standing by lantern light,
## glowing title text and a Start / Quit menu.

const Parallax := preload("res://scripts/parallax.gd")
const Atmosphere := preload("res://scripts/atmosphere.gd")
const Tiles := preload("res://scripts/tileset_factory.gd")
const Entities := preload("res://scripts/entities.gd")
const PixelText := preload("res://scripts/pixel_text.gd")
const MenuList := preload("res://scripts/ui/menu_list.gd")
const Fader := preload("res://scripts/ui/fader.gd")
const PLAYER_TEX := preload("res://assets/sprites/player.png")

var hero: Sprite2D
var fader: CanvasLayer
var menu: Node2D
var title: Node2D
var _t := 0.0
var _leaving := false


func _ready() -> void:
	get_tree().paused = false
	var speeds := [4.0, 10.0, 18.0, 28.0]
	var layers := Parallax.build_background(self)
	for i in layers.size():
		layers[i].autoscroll = Vector2(-speeds[i], 0)
	var fg := Parallax.build_foreground(self)
	fg.autoscroll = Vector2(-45, 0)

	var cam := Camera2D.new()
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.position = Vector2(192, 108)
	add_child(cam)

	# a ledge of rock for Wick to stand on
	var ground := TileMapLayer.new()
	ground.tile_set = Tiles.make()
	add_child(ground)
	for x in range(-1, 26):
		ground.set_cell(Vector2i(x, 12), 0, Vector2i(1, 0))
		ground.set_cell(Vector2i(x, 13), 0, Vector2i(0, 0), x % 4)
	var deco := TileMapLayer.new()
	deco.tile_set = Tiles.make()
	deco.z_index = -1
	add_child(deco)
	for x in range(2, 9):
		deco.set_cell(Vector2i(x, 11), 0, Vector2i(12 + x % 2, 1))
	deco.set_cell(Vector2i(17, 11), 0, Vector2i(11, 2))
	deco.set_cell(Vector2i(20, 11), 0, Vector2i(12, 2))

	var cart := Entities.create("minecart", Vector2(56, 192), {}, null)
	add_child(cart)
	hero = Sprite2D.new()
	hero.texture = PLAYER_TEX
	hero.hframes = 12
	hero.offset = Vector2(0, -12)
	hero.position = Vector2(104, 192)
	hero.z_index = 2
	add_child(hero)
	var lamp := Entities.light(Color(1, 0.86, 0.62), 1.4, 2.4, 0.0)
	lamp.position = Vector2(109, 174)
	add_child(lamp)
	add_child(Entities.create("lantern", Vector2(150, 120), {"chain": 120}, null))
	add_child(Entities.create("crystal", Vector2(300, 192), {"variant": 2}, null))
	add_child(Entities.create("crystal", Vector2(318, 192), {"variant": 0}, null))
	add_child(Entities.create("torch", Vector2(250, 150), {}, null))

	Atmosphere.build(self, cam)

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	title = PixelText.new()
	title.text = "HOLLOW MINE"
	title.size = 4
	title.align = 1
	title.position = Vector2(192, 30)
	title.shadow = Color(0.25, 0.05, 0.08, 1.0)
	ui.add_child(title)
	var sub := PixelText.new()
	sub.text = "A LANTERN-LIT DESCENT"
	sub.size = 2
	sub.align = 1
	sub.position = Vector2(192, 78)
	sub.color = Color(0.85, 0.8, 1.05)
	ui.add_child(sub)
	menu = MenuList.new()
	menu.position = Vector2(192, 112)
	ui.add_child(menu)
	menu.setup(["START GAME", "QUIT"])
	menu.chosen.connect(_on_chosen)
	var help := PixelText.new()
	help.text = "ARROWS/WASD MOVE   SPACE/Z JUMP   ESC PAUSE"
	help.align = 1
	help.position = Vector2(192, 204)
	help.color = Color(0.55, 0.52, 0.68)
	ui.add_child(help)

	fader = Fader.new()
	add_child(fader)
	fader.set_color(Color.BLACK)
	fader.fade_to(Color(0, 0, 0, 0), 1.0)
	Game.play_music()
	print("Title screen ready")


func _process(delta: float) -> void:
	_t += delta
	hero.frame = int(_t * 2.0) % 2
	var p := 0.5 + 0.5 * sin(_t * 1.6)
	title.color = Color(1.0, 0.66, 0.26).lerp(Color(1.0, 0.86, 0.5), p)


func _on_chosen(index: int) -> void:
	if _leaving:
		return
	if index == 0:
		_leaving = true
		menu.active = false
		await fader.fade_to(Color.BLACK, 0.6)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		get_tree().quit()
