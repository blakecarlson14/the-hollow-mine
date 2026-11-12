extends Node2D
## Stage controller: builds the level, parallax, lighting and UI; runs the
## death -> respawn / game over flow and the stage-clear sequence.

const PlayerScene := preload("res://scenes/player.tscn")
const Parallax := preload("res://scripts/parallax.gd")
const LevelScript := preload("res://scripts/level.gd")
const Atmosphere := preload("res://scripts/atmosphere.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const PauseMenu := preload("res://scripts/ui/pause_menu.gd")
const EndPanel := preload("res://scripts/ui/end_panel.gd")
const Fader := preload("res://scripts/ui/fader.gd")

const TITLE_SCENE := "res://scenes/title.tscn"
const GAME_SCENE := "res://scenes/game.tscn"
const PAR_TIME := 300.0

var level: Node2D
var player: CharacterBody2D
var hud: CanvasLayer
var pause_menu: CanvasLayer
var fader: CanvasLayer
var finished := false


func _ready() -> void:
	get_tree().paused = false
	Game.new_run()
	Parallax.build_background(self)
	level = LevelScript.new()
	level.name = "Level"
	add_child(level)
	level.build()

	player = PlayerScene.instantiate()
	player.position = level.spawn_point
	player.kill_y = level.size_px.y + 40.0
	add_child(player)
	player.died.connect(_on_player_died)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(level.size_px.x)
	cam.limit_bottom = int(level.size_px.y)
	cam.reset_smoothing()

	Parallax.build_foreground(self)
	Atmosphere.build(self, cam)

	hud = Hud.new()
	add_child(hud)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.restart_requested.connect(restart)
	pause_menu.quit_requested.connect(quit_to_title)
	fader = Fader.new()
	add_child(fader)
	fader.set_color(Color.BLACK)
	fader.fade_to(Color(0, 0, 0, 0), 0.8)

	Game.checkpoint_pos = level.spawn_point
	Game.timer_running = true
	Game.hud_changed.emit()
	Game.play_music()
	hud.show_banner("STAGE 1", "THE HOLLOW MINE")


func _on_player_died() -> void:
	Game.lives -= 1
	Game.deaths += 1
	Game.hud_changed.emit()
	if Game.lives <= 0:
		game_over()
		return
	await fader.fade_to(Color.BLACK, 0.3)
	Game.health = Game.MAX_HEALTH
	player.respawn(Game.checkpoint_pos)
	Game.hud_changed.emit()
	await get_tree().create_timer(0.15).timeout
	fader.fade_to(Color(0, 0, 0, 0), 0.4)


func game_over() -> void:
	Game.timer_running = false
	pause_menu.enabled = false
	finished = true
	var panel := EndPanel.new()
	add_child(panel)
	panel.restart_requested.connect(restart)
	panel.quit_requested.connect(quit_to_title)
	panel.present("GAME OVER", Color(1.0, 0.32, 0.28), [
		["SCORE", "%06d" % Game.score],
		["GEMS", "%d / %d" % [Game.gems, Game.gems_total]],
		["TIME", Game.format_time(Game.time)],
	], ["TRY AGAIN", "TITLE SCREEN"], Color(0.04, 0.0, 0.02, 0.82))


func stage_clear() -> void:
	if finished:
		return
	finished = true
	Game.timer_running = false
	pause_menu.enabled = false
	player.start_auto_walk()
	create_tween().tween_property(player.sprite, "modulate", Color(3.0, 2.8, 2.4, 0.0), 1.3)
	Game.stop_music()
	Game.sfx("clear")
	await fader.fade_to(Color(1.0, 0.95, 0.85, 1.0), 1.4)
	get_tree().paused = true
	var time_bonus := int(maxf(0.0, PAR_TIME - Game.time)) * 20
	var life_bonus := Game.lives * 1000
	var perfect := Game.gems >= Game.gems_total
	var gem_bonus := 5000 if perfect else 0
	var base := Game.score
	Game.score += time_bonus + life_bonus + gem_bonus
	var rows := [
		["CLEAR TIME", Game.format_time(Game.time)],
		["GEMS", "%d / %d" % [Game.gems, Game.gems_total]],
		["FOES STOMPED", str(Game.stomps)],
		["STAGE SCORE", "%06d" % base],
		["TIME BONUS", "+%d" % time_bonus],
		["LIVES BONUS", "+%d" % life_bonus],
	]
	if perfect:
		rows.append(["ALL GEMS!", "+5000", Color(1.0, 0.9, 0.35)])
	rows.append(["TOTAL SCORE", "%06d" % Game.score, Color(1.0, 0.95, 0.55)])
	var panel := EndPanel.new()
	add_child(panel)
	panel.restart_requested.connect(restart)
	panel.quit_requested.connect(quit_to_title)
	panel.present("STAGE CLEAR", Color(1.0, 0.82, 0.4), rows, ["PLAY AGAIN", "TITLE SCREEN"],
		Color(0.03, 0.02, 0.06, 0.97))
	fader.fade_to(Color(1, 0.95, 0.85, 0), 0.6)
	print("STAGE CLEAR time=", Game.format_time(Game.time), " score=", Game.score)


func restart() -> void:
	_change_scene(GAME_SCENE)


func quit_to_title() -> void:
	Game.stop_music()
	_change_scene(TITLE_SCENE)


func _change_scene(path: String) -> void:
	pause_menu.enabled = false
	await fader.fade_to(Color.BLACK, 0.35)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
