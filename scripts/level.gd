extends Node2D
## Level builder. The layout (scripts/level_layout.gd) calls the builder API below to mark
## solid cells, planks, decor and entities; build() then auto-tiles the TileMapLayers
## (16 edge variants), adds depth shading inside rock, and spawns entity nodes.

const Tiles := preload("res://scripts/tileset_factory.gd")
const Layout := preload("res://scripts/level_layout.gd")
const Entities := preload("res://scripts/entities.gd")

const T := 16
const W := 420
const H := 24

var solid := PackedByteArray()
var wall := PackedByteArray()
var planks: Dictionary = {}          # Vector2i -> true
var decor_back: Dictionary = {}      # Vector2i -> atlas coords
var decor_front: Dictionary = {}
var spawns: Array = []               # [kind, Vector2 pos, Dictionary args]
var ore_zones: Array = []            # [x0, x1, kind]
var no_decor: Dictionary = {}

var spawn_point := Vector2(64, 304)
var goal_x := 0.0
var size_px := Vector2(W * T, H * T)

var backwall_layer: TileMapLayer
var decor_back_layer: TileMapLayer
var ground_layer: TileMapLayer
var shade_layer: TileMapLayer
var decor_front_layer: TileMapLayer
var entity_root: Node2D

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	solid.resize(W * H)
	wall.resize(W * H)
	_rng.seed = 7331


func build() -> void:
	Layout.build(self)
	_default_ceiling()
	var ts := Tiles.make()
	backwall_layer = _make_layer("Backwall", ts, -6, false)
	decor_back_layer = _make_layer("DecorBack", ts, -5, false)
	entity_root = Node2D.new()
	entity_root.name = "Entities"
	add_child(entity_root)
	ground_layer = _make_layer("Ground", ts, 0, true)
	shade_layer = _make_layer("Shade", ts, 0, false)
	decor_front_layer = _make_layer("DecorFront", ts, -1, false)
	_paint()
	for s in spawns:
		var node: Node = Entities.create(s[0], s[1], s[2], self)
		if node:
			entity_root.add_child(node)


func _make_layer(n: String, ts: TileSet, z: int, collide: bool) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.name = n
	l.tile_set = ts
	l.z_index = z
	l.collision_enabled = collide
	add_child(l)
	return l


# =========================================================================== builder API

func is_solid(x: int, y: int) -> bool:
	if x < 0 or x >= W:
		return true
	if y < 0:
		return true
	if y >= H:
		return true
	return solid[y * W + x] == 1


func is_solid_px(p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / T), floori(p.y / T))
	if c.y >= H:
		return false
	return is_solid(c.x, c.y)


## True if the pixel lies inside solid rock or the top part of a plank.
func floor_at(p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / T), floori(p.y / T))
	if c.y >= H or c.y < 0:
		return false
	if is_solid(c.x, c.y):
		return true
	return planks.has(c) and fposmod(p.y, T) < 6.0


## True if there is rock or a plank within `rows` cells below the pixel.
func floor_below(p: Vector2, rows: int) -> bool:
	var cx := floori(p.x / T)
	var cy := floori(p.y / T)
	for y in range(cy, mini(cy + rows + 1, H)):
		if is_solid(cx, y) or planks.has(Vector2i(cx, y)):
			return true
	return false


func _put(x: int, y: int, v: int) -> void:
	if x >= 0 and x < W and y >= 0 and y < H:
		solid[y * W + x] = v


func block(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			_put(x, y, 1)


func clear(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			_put(x, y, 0)


func ground(x0: int, x1: int, top: int) -> void:
	block(x0, top, x1, H)


func ceiling(x0: int, x1: int, bottom: int) -> void:
	block(x0, 0, x1, bottom)
	for x in range(x0, x1):
		_set_wall_mark(x, -1)


func _set_wall_mark(x: int, _v: int) -> void:
	# columns with an explicit ceiling are skipped by the default ceiling pass
	no_decor[Vector2i(x, -1)] = true


func plank(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1):
		planks[Vector2i(x, y)] = true


func backwall(x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			if x >= 0 and x < W and y >= 0 and y < H:
				wall[y * W + x] = 1


## Timber support frame: posts at x0 and x1 standing on `floor_row`, cap beam on `top`.
func frame(x0: int, x1: int, top: int, floor_row: int) -> void:
	for y in range(top + 1, floor_row):
		decor_back[Vector2i(x0, y)] = Vector2i(0, 2)
		decor_back[Vector2i(x1, y)] = Vector2i(0, 2)
	decor_back[Vector2i(x0, top)] = Vector2i(1, 2)
	decor_back[Vector2i(x1, top)] = Vector2i(1, 2)
	for x in range(x0 + 1, x1):
		decor_back[Vector2i(x, top)] = Vector2i(3, 2)
	decor_back[Vector2i(x0 - 1, top)] = Vector2i(2, 2)
	decor_back[Vector2i(x1 + 1, top)] = Vector2i(4, 2)
	if x1 - x0 >= 4:
		decor_back[Vector2i(x0 + 1, top + 1)] = Vector2i(7, 2)
		decor_back[Vector2i(x1 - 1, top + 1)] = Vector2i(6, 2)


func rails(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1):
		decor_front[Vector2i(x, y)] = Vector2i(12 + (x % 2), 1)
		no_decor[Vector2i(x, y)] = true


func ore_zone(x0: int, x1: int, kind: String) -> void:
	ore_zones.append([x0, x1, kind])


## Entity at a ground position: tile column x, standing on top of row `top`.
func on_ground(kind: String, x: int, top: int, args: Dictionary = {}) -> void:
	spawns.append([kind, Vector2(x * T + 8, top * T), args])
	no_decor[Vector2i(x, top - 1)] = true


## Entity centred in cell (x, y).
func at_cell(kind: String, x: int, y: int, args: Dictionary = {}) -> void:
	spawns.append([kind, Vector2(x * T + 8, y * T + 8), args])


## Entity attached to the top edge of cell (x, y) (hanging things).
func at_top(kind: String, x: int, y: int, args: Dictionary = {}) -> void:
	spawns.append([kind, Vector2(x * T + 8, y * T), args])


## Moving lift between two pixel positions (centre of the plank's top surface).
func lift_px(from: Vector2, to: Vector2, period: float) -> void:
	spawns.append(["lift", from, {"to_px": to, "period": period}])


func gems(x0: int, x1: int, y: int, step: int = 1) -> void:
	for x in range(x0, x1, step):
		at_cell("gem", x, y)


func gem_arc(x0: int, x1: int, y: int, height: int) -> void:
	var n := x1 - x0
	for i in n:
		var t := (i + 0.5) / n
		var yy := y - int(round(sin(t * PI) * height))
		at_cell("gem", x0 + i, yy)


func start(x: int, top: int) -> void:
	spawn_point = Vector2(x * T + 8, top * T)


## Distance in pixels from a point up to the first solid cell above it.
func ceiling_distance(p: Vector2) -> float:
	var cx := floori(p.x / T)
	var cy := floori((p.y - 1.0) / T)
	var d := 0.0
	while cy >= 0 and not is_solid(cx, cy):
		cy -= 1
	return p.y - (cy + 1) * T


# =========================================================================== painting

func _default_ceiling() -> void:
	for x in W:
		if no_decor.has(Vector2i(x, -1)):
			continue
		var n := 0.5 + 0.5 * sin(x * 0.21) * cos(x * 0.073) + (_rng.randf() - 0.5) * 0.3
		var bottom := 1 + int(clampf(n, 0.0, 0.99) * 3.0)
		# never squeeze the play space: keep 7 free rows above the highest floor nearby
		var top_floor := H
		for xx in range(maxi(0, x - 1), mini(W, x + 2)):
			for y in range(H):
				if is_solid(xx, y) and y > 0:
					top_floor = mini(top_floor, y)
					break
		bottom = mini(bottom, top_floor - 7)
		for y in range(0, maxi(bottom, 1)):
			_put(x, y, 1)


func _mask(x: int, y: int, fn: Callable) -> int:
	var m := 0
	if not fn.call(x, y - 1):
		m |= 1
	if not fn.call(x + 1, y):
		m |= 2
	if not fn.call(x, y + 1):
		m |= 4
	if not fn.call(x - 1, y):
		m |= 8
	return m


func _depth(x: int, y: int) -> int:
	for d in range(1, 4):
		for o in [Vector2i(0, -d), Vector2i(0, d), Vector2i(-d, 0), Vector2i(d, 0)]:
			if not is_solid(x + o.x, y + o.y):
				return d
	return 4


func _ore_kind(x: int) -> String:
	for z in ore_zones:
		if x >= z[0] and x < z[1]:
			return z[2]
	return "amber"


func _paint() -> void:
	var solid_fn := func(x: int, y: int) -> bool: return is_solid(x, y)
	var wall_fn := func(x: int, y: int) -> bool:
		if x < 0 or x >= W or y < 0 or y >= H:
			return true
		return wall[y * W + x] == 1 or solid[y * W + x] == 1
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if is_solid(x, y):
				var m := _mask(x, y, solid_fn)
				var atlas := Vector2i(m, 0)
				var d := _depth(x, y)
				if m == 0:
					var r := _rng.randf()
					if d == 2 and r < 0.12:
						atlas = Vector2i(6 + _rng.randi_range(0, 1), 1) if _ore_kind(x) == "crystal" else Vector2i(4 + _rng.randi_range(0, 1), 1)
					elif r < 0.55:
						atlas = Vector2i(0, 0)
					else:
						atlas = Vector2i(_rng.randi_range(0, 3), 1)
				ground_layer.set_cell(c, 0, atlas, _rng.randi_range(0, 3) if m == 0 else 0)
				if d >= 3:
					shade_layer.set_cell(c, 0, Vector2i(0, 3), _rng.randi_range(0, 3))
				elif d == 2:
					var sm := 0
					if _depth_at(x, y - 1) < 2: sm |= 1
					if _depth_at(x + 1, y) < 2: sm |= 2
					if _depth_at(x, y + 1) < 2: sm |= 4
					if _depth_at(x - 1, y) < 2: sm |= 8
					shade_layer.set_cell(c, 0, Vector2i(sm, 3))
			elif wall[y * W + x] == 1:
				var wm := _mask(x, y, wall_fn)
				backwall_layer.set_cell(c, 0, Vector2i(wm, 3), _rng.randi_range(0, 3) if wm == 0 else 0)
	# one-way planks with end caps
	for c in planks:
		var l: bool = planks.has(c + Vector2i.LEFT)
		var r: bool = planks.has(c + Vector2i.RIGHT)
		var col := 9
		if not l and not r:
			col = 11
		elif not l:
			col = 8
		elif not r:
			col = 10
		ground_layer.set_cell(c, 0, Vector2i(col, 1))
	for c in decor_back:
		if not is_solid(c.x, c.y):
			decor_back_layer.set_cell(c, 0, decor_back[c])
	for c in decor_front:
		decor_front_layer.set_cell(c, 0, decor_front[c])
	# scatter small decor: stalactites under ceilings, rubble on floors, cobwebs in corners
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var c := Vector2i(x, y)
			if is_solid(x, y) or planks.has(c) or decor_back.has(c) or decor_front.has(c) or no_decor.has(c):
				continue
			var r := _rng.randf()
			if is_solid(x, y - 1) and not is_solid(x, y + 1) and r < 0.28:
				decor_front_layer.set_cell(c, 0, Vector2i(8 + _rng.randi_range(0, 1), 2))
			elif is_solid(x, y + 1) and not is_solid(x, y - 1) and r < 0.14:
				var pick: int = [10, 10, 10, 11, 12, 12, 13, 14][_rng.randi_range(0, 7)]
				decor_front_layer.set_cell(c, 0, Vector2i(pick, 2))
			elif is_solid(x, y - 1) and is_solid(x - 1, y) and r < 0.5:
				decor_front_layer.set_cell(c, 0, Vector2i(15, 2))


func _depth_at(x: int, y: int) -> int:
	if not is_solid(x, y):
		return 0
	return _depth(x, y)
