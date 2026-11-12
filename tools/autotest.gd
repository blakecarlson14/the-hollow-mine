extends Node
## Scripted test driver. Launch with:
##   godot --headless --path . res://scenes/game.tscn -- --autotest=<scenario>
## It injects input, logs what happens, prints "AUTOTEST PASS"/"AUTOTEST FAIL" and quits.

var scenario := "player"
var failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press(action: String) -> void:
	Input.action_press(action)


func _release(action: String) -> void:
	Input.action_release(action)


func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		failures.append(msg)


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _run() -> void:
	await _frames(5)
	print("AUTOTEST scenario=", scenario)
	if has_method("_scn_" + scenario):
		await call("_scn_" + scenario)
	else:
		failures.append("unknown scenario " + scenario)
	print("AUTOTEST ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)


# --------------------------------------------------------------------------- scenarios

## Windowed only: walks right and saves screenshots to the folder given by --shotdir=PATH.
func _scn_shots() -> void:
	var dir := OS.get_user_data_dir()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shotdir="):
			dir = arg.get_slice("=", 1)
	var p := _player()
	var stops: Array = [Vector2(48, 0)]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			stops.clear()
			for s in arg.get_slice("=", 1).split(";"):
				var xy := s.split(",")
				stops.append(Vector2(float(xy[0]), float(xy[1]) if xy.size() > 1 else 0.0))
	var i := 0
	for s in stops:
		if s.y != 0.0:
			p.respawn(Vector2(s.x * 16.0, s.y * 16.0))
		else:
			p.respawn(Vector2(s.x * 16.0, p.global_position.y))
		await _frames(50)
		var path := "%s/shot_%02d.png" % [dir, i]
		_screenshot(path)
		print("  saved ", path, " player=", p.global_position)
		i += 1


## Saves the viewport as an sRGB PNG at 2x (the HDR-2D viewport texture is linear).
func _screenshot(path: String) -> void:
	var src := get_viewport().get_texture().get_image()
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if get_viewport().use_hdr_2d:
				c = c.linear_to_srgb()
			c.a = 1.0
			out.set_pixel(x, y, c)
	out.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
	out.save_png(path)

func _scn_level() -> void:
	var game := get_tree().current_scene
	var lvl: Node = game.get("level")
	check(lvl != null, "level built")
	if lvl == null:
		return
	var ground: TileMapLayer = lvl.ground_layer
	check(ground.get_used_cells().size() > 3000, "ground tiles placed (%d)" % ground.get_used_cells().size())
	var kinds := {}
	for e in lvl.entity_root.get_children():
		var k: String = e.get_script().resource_path.get_file().get_basename()
		kinds[k] = kinds.get(k, 0) + 1
	print("  entities: ", kinds)
	check(kinds.get("gem", 0) > 40, "gems placed")
	check(kinds.get("checkpoint", 0) == 3, "three checkpoints")
	check(kinds.get("goal", 0) == 1, "goal placed")
	check(Game.gems_total == kinds.get("gem", 0), "gem total counted (%d)" % Game.gems_total)
	var p := _player()
	await _frames(30)
	check(p.is_on_floor(), "player standing at spawn %s" % p.global_position)
	# walk right through section A and check we stay on the level
	_press("move_right")
	await _frames(90)
	_release("move_right")
	check(p.global_position.x > 150.0, "walked to x=%.0f" % p.global_position.x)
	# teleport onto a lift and ride it
	var lift: Node2D = null
	for e in lvl.entity_root.get_children():
		if e is AnimatableBody2D:
			lift = e
			break
	check(lift != null, "lift exists")
	if lift:
		p.respawn(lift.global_position + Vector2(0, -2))
		await _frames(5)
		var x0: float = p.global_position.x
		var lx0: float = lift.global_position.x
		await _frames(60)
		check(p.is_on_floor(), "player standing on lift")
		check(absf((p.global_position.x - x0) - (lift.global_position.x - lx0)) < 6.0, "player carried by lift (p dx %.1f, lift dx %.1f)" % [p.global_position.x - x0, lift.global_position.x - lx0])
	# goal reachable trigger
	p.respawn(Vector2(408 * 16, 18 * 16))
	_press("move_right")
	await _frames(90)
	_release("move_right")
	check(game.get("finished") == true, "stage clear triggered at goal")


func _enemies_of(kind: String) -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_script().resource_path.get_file().get_basename() == kind:
			out.append(e)
	out.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	return out


func _reset_player(p: Node) -> void:
	Game.health = Game.MAX_HEALTH
	p.invuln = 0.0
	p.state = p.State.NORMAL


func _scn_enemies() -> void:
	var p := _player()
	var crawlers := _enemies_of("crawler")
	var hoppers := _enemies_of("hopper")
	var swoopers := _enemies_of("swooper")
	print("  crawlers=%d hoppers=%d swoopers=%d" % [crawlers.size(), hoppers.size(), swoopers.size()])
	check(crawlers.size() >= 8 and hoppers.size() >= 6 and swoopers.size() >= 6, "enemy counts")

	# 1. stomp from above
	var c: Node2D = crawlers[0]
	await _frames(10)
	_reset_player(p)
	var score0 := Game.score
	p.respawn(c.global_position + Vector2(0, -40))
	p.invuln = 0.0
	var bounced := false
	for i in 40:
		await _frames(1)
		if p.velocity.y < -100.0:
			bounced = true
		if not c.is_alive():
			break
	check(not c.is_alive(), "crawler killed by stomp from above")
	check(bounced, "player bounced off the stomp")
	check(Game.health == Game.MAX_HEALTH, "no damage from stomping (health %d)" % Game.health)
	check(Game.score > score0, "stomp scored (%d)" % (Game.score - score0))

	# 2. side contact hurts
	var c2: Node2D = crawlers[1]
	await _frames(20)
	_reset_player(p)
	p.respawn(c2.global_position + Vector2(-40, 0))
	await _frames(2)
	p.invuln = 0.0
	_press("move_right")
	for i in 60:
		await _frames(1)
		if Game.health < Game.MAX_HEALTH:
			break
	_release("move_right")
	check(Game.health == Game.MAX_HEALTH - 1, "side contact with crawler hurts (health %d)" % Game.health)
	check(c2.is_alive(), "crawler survives side contact")

	# 3. contact from below hurts (jump up into a hovering swooper)
	var s: Node2D = swoopers[0]
	await _frames(30)
	_reset_player(p)
	s.set_physics_process(false)
	var below: Vector2 = s.global_position + Vector2(0, 30)
	p.respawn(below)
	p.invuln = 0.0
	p.velocity = Vector2(0, -260)
	for i in 30:
		await _frames(1)
		if Game.health < Game.MAX_HEALTH:
			break
	check(Game.health == Game.MAX_HEALTH - 1, "contact from below hurts (health %d)" % Game.health)
	check(s.is_alive(), "swooper survives contact from below")
	s.set_physics_process(true)

	# 4. stomp a flying swooper from above
	s.set_physics_process(false)
	p.respawn(s.global_position + Vector2(0, -36))
	_reset_player(p)
	for i in 40:
		await _frames(1)
		if not s.is_alive():
			break
	check(not s.is_alive(), "swooper stomped from above")
	check(Game.health == Game.MAX_HEALTH, "no damage stomping swooper")

	# 5. hopper actually hops
	var h: Node2D = hoppers[0]
	p.respawn(h.global_position + Vector2(-90, 0))
	_reset_player(p)
	p.freeze()
	var hy: float = h.global_position.y
	var min_hy := hy
	for i in 180:
		await _frames(1)
		min_hy = minf(min_hy, h.global_position.y)
	check(hy - min_hy > 15.0, "hopper hops (%.1f px)" % (hy - min_hy))
	p.state = p.State.NORMAL

	# 6. spikes hurt
	var sp: Node2D = null
	for hz in get_tree().get_nodes_in_group("hazards"):
		if hz.get_script().resource_path.ends_with("spikes.gd"):
			sp = hz
			break
	_reset_player(p)
	p.respawn(sp.global_position + Vector2(0, -30))
	p.invuln = 0.0
	for i in 40:
		await _frames(1)
		if Game.health < Game.MAX_HEALTH:
			break
	check(Game.health == Game.MAX_HEALTH - 1, "spikes hurt (health %d)" % Game.health)

	# 7. falling rock hits a player standing underneath
	var rock: Node2D = null
	for hz in get_tree().get_nodes_in_group("hazards"):
		if hz.get_script().resource_path.ends_with("rock.gd"):
			rock = hz
			break
	_reset_player(p)
	await _frames(100)
	_reset_player(p)
	p.respawn(Vector2(rock.global_position.x, 18 * 16))
	p.invuln = 0.0
	var hit := false
	for i in 120:
		await _frames(1)
		if Game.health < Game.MAX_HEALTH:
			hit = true
			break
	check(hit, "falling rock hurts player underneath")
	await _frames(40)
	check(rock.state == rock.S.GONE, "rock shattered on the floor")

	# 8. losing all health costs a life and respawns at the checkpoint
	_reset_player(p)
	var lives0 := Game.lives
	Game.health = 1
	p.invuln = 0.0
	p.take_damage(p.global_position.x + 10)
	await _frames(130)
	check(Game.lives == lives0 - 1, "life lost on death (%d -> %d)" % [lives0, Game.lives])
	check(p.state == p.State.NORMAL and Game.health == Game.MAX_HEALTH, "respawned with full health")
	# 9. pit death
	lives0 = Game.lives
	p.respawn(Vector2(233 * 16 + 8, 16 * 16))
	p.invuln = 0.0
	await _frames(150)
	check(Game.lives == lives0 - 1, "falling into a pit costs a life")


func _scn_player() -> void:
	var p := _player()
	check(p != null, "player exists")
	if p == null:
		return
	await _frames(20)
	check(p.is_on_floor(), "player lands on ground (y=%.1f)" % p.global_position.y)
	var x0: float = p.global_position.x
	_press("move_right")
	await _frames(40)
	check(p.global_position.x > x0 + 50.0, "runs right (dx=%.1f)" % (p.global_position.x - x0))
	var y0: float = p.global_position.y
	_press("jump")
	var min_y := y0
	for i in 40:
		await _frames(1)
		min_y = minf(min_y, p.global_position.y)
	_release("jump")
	check(y0 - min_y > 40.0, "full jump height %.1f px" % (y0 - min_y))
	await _frames(30)
	_release("move_right")
	# short hop
	await _frames(20)
	y0 = p.global_position.y
	min_y = y0
	_press("jump")
	await _frames(3)
	_release("jump")
	for i in 30:
		await _frames(1)
		min_y = minf(min_y, p.global_position.y)
	check(y0 - min_y < 30.0, "short hop height %.1f px (variable jump)" % (y0 - min_y))
	print("  player at ", p.global_position)


func _scn_ui() -> void:
	var game := get_tree().current_scene
	await _frames(30)
	await _tap("pause")
	await _frames(3)
	check(get_tree().paused and game.pause_menu.visible, "pause menu opens and pauses the game")
	await _tap("move_down")
	check(game.pause_menu.menu.selected == 1, "menu navigation works")
	await _tap("move_up")
	await _tap("accept")
	await _frames(3)
	check(not get_tree().paused and not game.pause_menu.visible, "RESUME closes the menu")
	await _tap("pause")
	await _frames(2)
	await _tap("pause")
	await _frames(2)
	check(not get_tree().paused, "pause key toggles the menu off again")
	# game over
	Game.lives = 1
	var p := _player()
	p.invuln = 0.0
	Game.health = 1
	p.take_damage(p.global_position.x + 5.0)
	await _frames(150)
	var panel := _end_panel()
	check(panel != null and panel.visible, "GAME OVER panel shown after last life")
	check(Game.lives == 0, "no lives left")


func _scn_clear() -> void:
	var game := get_tree().current_scene
	var p := _player()
	await _frames(20)
	p.respawn(Vector2(405 * 16, 18 * 16))
	_press("move_right")
	await _frames(100)
	_release("move_right")
	check(game.finished, "goal reached")
	await _wait(1.8)
	var panel := _end_panel()
	check(panel != null and panel.visible, "STAGE CLEAR panel shown")
	check(get_tree().paused, "game paused behind results")
	print("  final score=", Game.score, " time=", Game.format_time(Game.time))
	await _wait(3.5)
	check(panel.menu.visible, "results menu visible")
	print("  menu active=", panel.menu.active, " vis_in_tree=", panel.menu.is_visible_in_tree(), " labels=", panel.menu.labels.size(), " pm=", panel.menu.process_mode, " can_process=", panel.menu.can_process())
	await _tap("accept")
	await _wait(1.0)
	var g2 := get_tree().current_scene
	check(g2 != game and g2.name == "Stage" and not g2.finished, "PLAY AGAIN restarts the stage")
	check(not get_tree().paused, "tree unpaused after restart")


func _scn_title() -> void:
	var t := get_tree().current_scene
	check(t.name == "Title", "title scene loaded")
	await _frames(60)
	await _tap("accept")
	await _wait(1.2)
	print("  current scene: ", get_tree().current_scene, " ", get_tree().current_scene.name if get_tree().current_scene else "")
	check(get_tree().current_scene != null and get_tree().current_scene.name == "Stage", "START GAME loads the stage")
	await _frames(30)
	check(_player() != null and _player().is_on_floor(), "player spawned in stage")


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _shotdir() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shotdir="):
			return arg.get_slice("=", 1)
	return OS.get_user_data_dir()


func _scn_titleshot() -> void:
	await _wait(2.0)
	_screenshot(_shotdir() + "/ui_title.png")


func _scn_uishots() -> void:
	var d := _shotdir()
	var p := _player()
	await _wait(1.2)
	_screenshot(d + "/ui_banner.png")
	await _tap("pause")
	await _wait(0.3)
	_screenshot(d + "/ui_pause.png")
	await _tap("pause")
	p.respawn(Vector2(405 * 16, 18 * 16))
	Game.gems = 61
	_press("move_right")
	await _wait(1.0)
	_release("move_right")
	await _wait(6.0)
	_screenshot(d + "/ui_clear.png")


# --------------------------------------------------------------------------- playthrough bot

func _lifts() -> Array:
	var out := []
	for e in get_tree().current_scene.level.entity_root.get_children():
		if e is AnimatableBody2D:
			out.append(e)
	return out


func _on_lift(p: CharacterBody2D) -> bool:
	for i in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		if c.get_normal().y < -0.5 and c.get_collider() is AnimatableBody2D:
			return true
	return false


## Is there something to land on within jumping reach ahead?
func _landing_ahead(lvl: Node, pos: Vector2) -> bool:
	var row := floori((pos.y - 1.0) / 16.0)
	for dx in range(24, 76, 6):
		var cx := floori((pos.x + dx) / 16.0)
		for r in range(row - 3, row + 5):
			if r < 0 or r >= 24:
				continue
			var solid_here: bool = lvl.is_solid(cx, r) or lvl.planks.has(Vector2i(cx, r))
			if solid_here and not lvl.is_solid(cx, r - 1):
				return true
	return false


func _scn_bot() -> void:
	var scene := get_tree().current_scene
	var lvl: Node = scene.level
	var p: CharacterBody2D = _player()
	var dt := 1.0 / 60.0
	var t := 0.0
	var best_x := 0.0
	var stuck := 0.0
	var assists: Array = []
	var jump_hold := 0
	var last_report := 0
	while t < 900.0 and not scene.finished:
		await get_tree().physics_frame
		t += dt
		Game.lives = 99
		if "--god" in OS.get_cmdline_user_args():
			p.invuln = 0.5
		if p.state == p.State.DEAD:
			_release("move_right")
			_release("jump")
			continue
		var pos := p.global_position
		if jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0 or (jump_hold < 14 and p.velocity.y >= 0.0):
				_release("jump")
				jump_hold = 0
		var on_floor := p.is_on_floor()
		var wall: bool = lvl.is_solid_px(pos + Vector2(10, -6)) or lvl.is_solid_px(pos + Vector2(10, -15))
		var gap: bool = not lvl.floor_below(pos + Vector2(10, 1), 2)
		var enemy_near := false
		for e in get_tree().get_nodes_in_group("enemies"):
			var d: Vector2 = e.global_position - pos
			if d.x > 0 and d.x < 42 and absf(d.y) < 28:
				enemy_near = true
		var go := true
		var want_jump := false
		if on_floor:
			if wall or enemy_near:
				want_jump = true
			elif lvl.is_solid_px(pos + Vector2(90, -60)) and lvl.is_solid_px(pos + Vector2(90, -8)):
				var r0 := floori((pos.y - 1.0) / 16.0)
				for dx in [8, 16, 24]:
					for dr in [2, 3]:
						if lvl.planks.has(Vector2i(floori((pos.x + dx) / 16.0), r0 - dr)):
							want_jump = true
			elif gap:
				if _landing_ahead(lvl, pos):
					want_jump = true
				elif lvl.floor_below(pos + Vector2(14, 1), 9) and not _lifts().any(func(l): return absf(l.global_position.x - pos.x) < 140.0):
					go = true
				else:
					go = false
					for l in _lifts():
						var lx: float = l.global_position.x - 24.0
						if lx > pos.x - 8 and lx - pos.x < 40 and l.global_position.y > pos.y - 40 and l.global_position.y < pos.y + 30:
							want_jump = true
							go = true
			if _on_lift(p) and gap and not _landing_ahead(lvl, pos):
				go = false
				want_jump = false
		if "--trace" in OS.get_cmdline_user_args() and pos.x > 290 and pos.x < 330 and Engine.get_physics_frames() % 6 == 0:
			print("   trace pos=%s vel=%s floor=%s wall=%s gap=%s enemy=%s go=%s jump=%s hold=%d" % [pos.round(), p.velocity.round(), on_floor, wall, gap, enemy_near, go, want_jump, jump_hold])
		if go:
			_press("move_right")
		else:
			_release("move_right")
		if want_jump and jump_hold == 0:
			_press("jump")
			jump_hold = 22
		# progress tracking + assists
		if pos.x > best_x + 4.0:
			best_x = pos.x
			stuck = 0.0
		else:
			stuck += dt
		if stuck > 12.0:
			var cx := floori(best_x / 16.0) + 3
			var placed := false
			while cx < 418 and not placed:
				for r in range(4, 23):
					if lvl.is_solid(cx, r) and not lvl.is_solid(cx, r - 1) and not lvl.is_solid(cx, r - 2):
						p.respawn(Vector2(cx * 16 + 8, r * 16))
						placed = true
						break
				cx += 1
			assists.append(int(best_x / 16.0))
			stuck = 0.0
			best_x = p.global_position.x
		if int(t) / 30 != last_report:
			last_report = int(t) / 30
			print("  t=%3ds x=%4d tile=%3d deaths=%d gems=%d" % [int(t), int(pos.x), int(pos.x / 16.0), Game.deaths, Game.gems])
	_release("move_right")
	_release("jump")
	print("  bot finished=%s sim_time=%.1fs deaths=%d gems=%d/%d stomps=%d assists(tile x)=%s" % [scene.finished, t, Game.deaths, Game.gems, Game.gems_total, Game.stomps, assists])
	check(scene.finished, "bot reached the goal")


func _jump_when(p: CharacterBody2D, cond: Callable, max_frames: int = 600) -> bool:
	for i in max_frames:
		await _frames(1)
		if p.is_on_floor() and cond.call():
			_press("jump")
			await _frames(18)
			_release("jump")
			return true
	return false


func _land(p: CharacterBody2D) -> void:
	for i in 120:
		await _frames(1)
		if p.is_on_floor() and p.velocity.y >= 0.0:
			return


func _scn_routes() -> void:
	var p: CharacterBody2D = _player()
	var lifts := _lifts()
	lifts.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	# 1. plank staircase up to the checkpoint-1 plateau
	p.respawn(Vector2(71 * 16, 18 * 16))
	await _frames(10)
	_press("move_right")
	await _jump_when(p, func(): return p.global_position.x >= 1160.0)
	await _land(p)
	check(absf(p.global_position.y - 240.0) < 2.0, "landed on first plank (y=%.0f)" % p.global_position.y)
	await _jump_when(p, func(): return p.global_position.x >= 1222.0)
	await _land(p)
	check(absf(p.global_position.y - 192.0) < 2.0, "landed on second plank (y=%.0f)" % p.global_position.y)
	await _jump_when(p, func(): return p.global_position.x >= 1286.0)
	await _land(p)
	_release("move_right")
	check(absf(p.global_position.y - 160.0) < 2.0 and p.global_position.x > 1328.0, "reached the plateau %s" % p.global_position)

	# 1b. first horizontal lift: walk on from the ledge, hop up onto the rock island
	var h1: Node2D = lifts[0]
	p.respawn(Vector2(142 * 16 - 8, 18 * 16))
	await _frames(10)
	for i in 900:
		await _frames(1)
		if h1.global_position.x - 24.0 < 2268.0:
			break
	_press("move_right")
	await _frames(16)
	_release("move_right")
	await _land(p)
	check(_on_lift(p), "walked onto the first lift without jumping")
	for i in 900:
		await _frames(1)
		if h1.global_position.x + 24.0 > 2500.0:
			break
	_press("move_right")
	_press("jump")
	await _frames(16)
	_release("jump")
	await _frames(10)
	_release("move_right")
	await _land(p)
	check(absf(p.global_position.y - 256.0) < 2.0 and p.global_position.x > 2496.0, "hopped onto the rock island %s" % p.global_position)

	# 2. vertical lift from the rock island to the high ledge
	var vl: Node2D = lifts[1]
	p.respawn(Vector2(159 * 16 - 5, 16 * 16))
	await _frames(10)
	for i in 600:
		await _frames(1)
		if vl.global_position.y > 250.0 and vl.position.y > vl.get("from").y - 4.0 and i > 5:
			break
	_press("move_right")
	_press("jump")
	await _frames(14)
	_release("jump")
	await _frames(14)
	_release("move_right")
	await _land(p)
	check(_on_lift(p), "jumped onto the vertical lift")
	for i in 600:
		await _frames(1)
		if vl.global_position.y < 180.0:
			break
	_press("move_right")
	_press("jump")
	await _frames(16)
	_release("jump")
	await _frames(24)
	_release("move_right")
	await _land(p)
	check(absf(p.global_position.y - 192.0) < 2.0 and p.global_position.x > 2624.0, "jumped across to the ledge %s" % p.global_position)

	# 3. horizontal lift over the pit in section H
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	var hl: Node2D = lifts[2]
	p.respawn(Vector2(289 * 16 - 8, 16 * 16))
	await _frames(10)
	for i in 900:
		await _frames(1)
		if hl.global_position.x - 24.0 < 4620.0:
			break
	_press("move_right")
	await _frames(16)
	_release("move_right")
	await _land(p)
	check(_on_lift(p), "walked onto the horizontal lift without jumping")
	for i in 900:
		await _frames(1)
		if hl.global_position.x + 24.0 > 4820.0:
			break
	_press("move_right")
	await _frames(36)
	_release("move_right")
	await _land(p)
	check(p.global_position.x > 4816.0 and absf(p.global_position.y - 256.0) < 2.0, "crossed to the far side %s" % p.global_position)


func _tap(action: String) -> void:
	await get_tree().process_frame
	_press(action)
	await get_tree().process_frame
	await get_tree().process_frame
	_release(action)
	await get_tree().process_frame


func _end_panel() -> Node:
	for c in get_tree().current_scene.get_children():
		if c.get_script() and c.get_script().resource_path.ends_with("end_panel.gd"):
			return c
	return null
