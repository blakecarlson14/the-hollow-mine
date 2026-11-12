extends RefCounted
## Generates assets/tiles/tiles.png - a 16x4 atlas of 16x16 tiles.
##
## Row 0: solid stone, column = exposed-edge mask (1=up, 2=right, 4=down, 8=left)
## Row 1: 0-3 stone interior variants, 4-5 amber ore veins, 6-7 crystal veins,
##        8-11 one-way wood platform (left, mid, right, single), 12-13 rails,
##        14 boarded wall, 15 iron grate
## Row 2: decor - 0 post, 1 post+cap, 2-4 crossbeam L/M/R, 5 chain, 6-7 braces,
##        8-9 hanging stalactites, 10 pebbles, 11 skull, 12 glow fungus, 13 crate,
##        14 barrel, 15 cobweb
## Row 3: back wall (dark rock, no collision), column = exposed-edge mask

const L := preload("res://tools/art_lib.gd")
const T := 16


static func generate() -> void:
	var im := L.img(T * 16, T * 4)
	for m in 16:
		_stone(im, m * T, 0, m, 0)
		_backwall(im, m * T, 3 * T, m)
	for v in 4:
		_stone(im, v * T, T, 0, v)
	_ore(im, 4 * T, T, L.AMBER, 11)
	_ore(im, 5 * T, T, L.AMBER, 23)
	_ore(im, 6 * T, T, L.CRYS, 37)
	_ore(im, 7 * T, T, L.CRYS, 41)
	_platform(im, 8 * T, T, true, false)
	_platform(im, 9 * T, T, false, false)
	_platform(im, 10 * T, T, false, true)
	_platform(im, 11 * T, T, true, true)
	_rail(im, 12 * T, T, false)
	_rail(im, 13 * T, T, true)
	_boards(im, 14 * T, T)
	_grate(im, 15 * T, T)
	_decor(im)
	L.save(im, "res://assets/tiles/tiles.png")


# --------------------------------------------------------------------------- stone

static func _stone_base(x: int, y: int) -> float:
	# Periodic over 16px so every stone tile joins seamlessly.
	var v := L.fbm(x / 4.0, y / 4.0, 5, 4, 4, 3)
	var strata := 0.08 * sin((y + 2.0 * sin(x * 0.4)) * 0.9)
	return v + strata


static func _stone(im: Image, ox: int, oy: int, mask: int, variant: int) -> void:
	var pal := [L.STONE[1], L.STONE[2], L.STONE[3], L.STONE[4]]
	for y in T:
		for x in T:
			var v := _stone_base(x, y) * 1.15 - 0.12
			var col: Color = L.ramp(pal, v, x, y)
			# crack lines from ridged noise
			var r := absf(L.fbm(x / 5.33, y / 5.33, 9, 3, 3, 2) - 0.5)
			if r < 0.022:
				col = L.STONE[1]
			elif r < 0.045 and L.h2(x, y, 3) > 0.7:
				col = L.STONE[1]
			L.px(im, ox + x, oy + y, col)
	# interior variants: features kept away from tile borders so seams stay clean
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + variant
	if variant == 1:
		for i in 2:
			var sx := rng.randi_range(3, 12)
			var sy := rng.randi_range(3, 12)
			for k in 5:
				L.px(im, ox + sx, oy + sy, L.STONE[0])
				sx = clampi(sx + rng.randi_range(-1, 1), 2, 13)
				sy = clampi(sy + 1, 2, 13)
	elif variant == 2:
		for i in 4:
			var cx := rng.randi_range(3, 12)
			var cy := rng.randi_range(3, 12)
			L.ellipse(im, ox + cx + 0.5, oy + cy + 0.5, 1.6, 1.2, L.STONE[4])
			L.px(im, ox + cx, oy + cy, L.STONE[5])
			L.px(im, ox + cx + 1, oy + cy + 1, L.STONE[1])
	elif variant == 3:
		L.ellipse(im, ox + 8, oy + 8, 4.0, 3.0, L.STONE[3])
		L.line(im, ox + 5, oy + 7, ox + 10, oy + 6, L.STONE[5])
		L.line(im, ox + 5, oy + 10, ox + 11, oy + 10, L.STONE[1])
	_edges(im, ox, oy, mask)


static func _edges(im: Image, ox: int, oy: int, mask: int) -> void:
	var up := mask & 1 != 0
	var right := mask & 2 != 0
	var down := mask & 4 != 0
	var left := mask & 8 != 0
	if left:
		for y in T:
			L.px(im, ox, oy + y, L.STONE[1])
			L.px(im, ox + 1, oy + y, L.STONE[4] if L.h2(1, y, 8) > 0.35 else L.STONE[3])
	if right:
		for y in T:
			L.px(im, ox + 15, oy + y, L.STONE[0])
			L.px(im, ox + 14, oy + y, L.STONE[1] if L.h2(14, y, 8) > 0.5 else L.STONE[2])
	if up:
		for x in T:
			var d := 2 + int(L.h2(x, 0, 77) * 2.2)
			for y in d:
				var col: Color = L.STONE[6] if y == 0 else (L.STONE[5] if y == 1 else L.STONE[4])
				if y == 0 and L.h2(x, 1, 78) > 0.8:
					col = L.STONE[5]
				L.px(im, ox + x, oy + y, col)
			L.px(im, ox + x, oy + d, L.STONE[1])
			# occasional gravel speck
			if L.h2(x, 2, 79) > 0.85:
				L.px(im, ox + x, oy + d + 1, L.STONE[4])
	if down:
		for x in T:
			L.px(im, ox + x, oy + 15, L.STONE[0])
			L.px(im, ox + x, oy + 14, L.STONE[1])
			if L.h2(x, 13, 80) > 0.6:
				L.px(im, ox + x, oy + 13, L.STONE[1])
	var clear := Color(0, 0, 0, 0)
	if up and left:
		for p in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			L.px(im, ox + p.x, oy + p.y, clear)
		L.px(im, ox + 1, oy + 1, L.STONE[5])
	if up and right:
		for p in [Vector2i(15, 0), Vector2i(14, 0), Vector2i(15, 1)]:
			L.px(im, ox + p.x, oy + p.y, clear)
		L.px(im, ox + 14, oy + 1, L.STONE[5])
	if down and left:
		for p in [Vector2i(0, 15), Vector2i(1, 15), Vector2i(0, 14)]:
			L.px(im, ox + p.x, oy + p.y, clear)
	if down and right:
		for p in [Vector2i(15, 15), Vector2i(14, 15), Vector2i(15, 14)]:
			L.px(im, ox + p.x, oy + p.y, clear)


static func _ore(im: Image, ox: int, oy: int, pal: Array, s: int) -> void:
	_stone(im, ox, oy, 0, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var x := rng.randi_range(3, 5)
	var y := rng.randi_range(3, 12)
	for i in 10:
		L.px(im, ox + x, oy + y, pal[2])
		L.px(im, ox + x, oy + y + 1, pal[1])
		if i % 3 == 1:
			L.px(im, ox + x, oy + y - 1, pal[3])
		x = clampi(x + 1, 2, 13)
		y = clampi(y + rng.randi_range(-1, 1), 2, 12)
	for i in 3:
		var cx := rng.randi_range(3, 12)
		var cy := rng.randi_range(3, 12)
		L.px(im, ox + cx, oy + cy, pal[3])
		L.px(im, ox + cx + 1, oy + cy, pal[2])
		L.px(im, ox + cx, oy + cy - 1, pal[4])
		L.px(im, ox + cx, oy + cy + 1, pal[1])


static func _backwall(im: Image, ox: int, oy: int, mask: int) -> void:
	var pal := [L.STONE[0], L.STONE[1], L.STONE[2]]
	for y in T:
		for x in T:
			var v := _stone_base(x + 7, y + 3) * 1.1 - 0.15
			var col: Color = L.ramp(pal, v, x, y)
			var r := absf(L.fbm(x / 5.33, y / 5.33, 19, 3, 3, 2) - 0.5)
			if r < 0.025 and L.h2(x, y, 5) > 0.4:
				col = L.STONE[0].darkened(0.3)
			# exposed sides dissolve into the background with dithering
			var dist := 99.0
			if mask & 1:
				dist = minf(dist, y)
			if mask & 2:
				dist = minf(dist, 15 - x)
			if mask & 4:
				dist = minf(dist, 15 - y)
			if mask & 8:
				dist = minf(dist, x)
			if dist < 5 and (dist / 5.0) < L.dither(x, y) + L.h2(x, y, 4) * 0.25:
				continue
			L.px(im, ox + x, oy + y, col)


# --------------------------------------------------------------------------- wood + iron

static func _plank_row(im: Image, ox: int, oy: int, x0: int, x1: int) -> void:
	for x in range(x0, x1):
		L.px(im, ox + x, oy, L.WOOD[5])
		L.px(im, ox + x, oy + 1, L.WOOD[4])
		L.px(im, ox + x, oy + 2, L.WOOD[3])
		L.px(im, ox + x, oy + 3, L.WOOD[3] if L.h2(x, 3, 50) > 0.3 else L.WOOD[2])
		L.px(im, ox + x, oy + 4, L.WOOD[2])
		L.px(im, ox + x, oy + 5, L.WOOD[1])
		if L.h2(x, 0, 51) > 0.82:
			L.px(im, ox + x, oy + 2, L.WOOD[2])


static func _platform(im: Image, ox: int, oy: int, left_end: bool, right_end: bool) -> void:
	_plank_row(im, ox, oy, 0, T)
	# plank seam and nails
	L.px(im, ox + 8, oy + 1, L.WOOD[2])
	L.px(im, ox + 8, oy + 2, L.WOOD[1])
	L.px(im, ox + 8, oy + 3, L.WOOD[1])
	L.px(im, ox + 8, oy + 4, L.WOOD[1])
	L.px(im, ox + 3, oy + 3, L.METAL[3])
	L.px(im, ox + 12, oy + 3, L.METAL[3])
	if left_end:
		for y in 6:
			L.px(im, ox, oy + y, L.WOOD[0])
		L.px(im, ox + 1, oy, L.WOOD[4])
		_brace(im, ox + 2, oy + 6, 1)
	if right_end:
		for y in 6:
			L.px(im, ox + 15, oy + y, L.WOOD[0])
		_brace(im, ox + 13, oy + 6, -1)


static func _brace(im: Image, x: int, y: int, dir: int) -> void:
	# small iron bracket hanging under a platform end
	for i in 6:
		L.px(im, x + i * dir, y + i, L.METAL[2])
		L.px(im, x + i * dir, y + i + 1, L.METAL[1])
	L.rect(im, x - (1 if dir < 0 else 0), y, 2, 7, L.METAL[1])
	L.px(im, x, y, L.METAL[3])


static func _rail(im: Image, ox: int, oy: int, bolt: bool) -> void:
	# ties
	for tx in [1, 9]:
		L.rect(im, ox + tx, oy + 13, 6, 3, L.WOOD[2])
		L.rect(im, ox + tx, oy + 13, 6, 1, L.WOOD[3])
		L.px(im, ox + tx, oy + 15, L.WOOD[0])
	# rail
	for x in T:
		L.px(im, ox + x, oy + 10, L.METAL[4])
		L.px(im, ox + x, oy + 11, L.METAL[3])
		L.px(im, ox + x, oy + 12, L.METAL[1])
	if bolt:
		L.px(im, ox + 4, oy + 11, L.METAL[2])
		L.px(im, ox + 12, oy + 11, L.METAL[2])
	else:
		L.px(im, ox + 7, oy + 10, L.RUST[3])
		L.px(im, ox + 8, oy + 11, L.RUST[2])


static func _boards(im: Image, ox: int, oy: int) -> void:
	for y in T:
		for x in T:
			var board := x / 4
			var col: Color = L.WOOD[1] if board % 2 == 0 else L.WOOD[2]
			if x % 4 == 0:
				col = L.WOOD[0]
			elif L.h2(x, y, 60 + board) > 0.85:
				col = L.WOOD[0]
			L.px(im, ox + x, oy + y, col)
	for x in T:
		L.px(im, ox + x, oy + 4, L.WOOD[3])
		L.px(im, ox + x, oy + 5, L.WOOD[1])
		L.px(im, ox + x, oy + 11, L.WOOD[3])
		L.px(im, ox + x, oy + 12, L.WOOD[1])


static func _grate(im: Image, ox: int, oy: int) -> void:
	for i in 4:
		var x := 1 + i * 4
		L.rect(im, ox + x, oy, 2, T, L.METAL[1])
		L.rect(im, ox + x, oy, 1, T, L.METAL[2])
		var y := 1 + i * 4
		L.rect(im, ox, oy + y, T, 2, L.METAL[1])
		L.rect(im, ox, oy + y, T, 1, L.METAL[2])
	L.px(im, ox + 5, oy + 9, L.RUST[2])
	L.px(im, ox + 10, oy + 4, L.RUST[2])


static func _post(im: Image, ox: int, oy: int, y0: int, y1: int) -> void:
	for y in range(y0, y1):
		L.px(im, ox + 4, oy + y, L.WOOD[0])
		L.px(im, ox + 5, oy + y, L.WOOD[3])
		for x in range(6, 10):
			L.px(im, ox + x, oy + y, L.WOOD[2] if L.h2(x, y, 70) > 0.2 else L.WOOD[1])
		L.px(im, ox + 10, oy + y, L.WOOD[1])
		L.px(im, ox + 11, oy + y, L.WOOD[0])


static func _beam(im: Image, ox: int, oy: int, x0: int, x1: int) -> void:
	for x in range(x0, x1):
		L.px(im, ox + x, oy + 0, L.WOOD[0])
		L.px(im, ox + x, oy + 1, L.WOOD[3])
		L.px(im, ox + x, oy + 2, L.WOOD[2])
		L.px(im, ox + x, oy + 3, L.WOOD[2] if L.h2(x, 3, 71) > 0.25 else L.WOOD[1])
		L.px(im, ox + x, oy + 4, L.WOOD[1])
		L.px(im, ox + x, oy + 5, L.WOOD[0])


static func _decor(im: Image) -> void:
	var oy := 2 * T
	# 0 post
	_post(im, 0, oy, 0, T)
	# 1 post with cap beam
	_post(im, T, oy, 0, T)
	_beam(im, T, oy, 0, T)
	L.rect(im, T + 4, oy + 6, 8, 2, L.METAL[1])
	L.px(im, T + 5, oy + 6, L.METAL[3])
	L.px(im, T + 10, oy + 6, L.METAL[3])
	# 2-4 crossbeam L/M/R
	_beam(im, 2 * T, oy, 4, T)
	L.rect(im, 2 * T + 3, oy, 1, 6, L.WOOD[0])
	_beam(im, 3 * T, oy, 0, T)
	_beam(im, 4 * T, oy, 0, 12)
	L.rect(im, 4 * T + 12, oy, 1, 6, L.WOOD[0])
	# 5 chain (links repeat every 8px)
	for k in 2:
		var cy := oy + k * 8
		L.rect(im, 5 * T + 6, cy, 4, 1, L.METAL[3])
		L.rect(im, 5 * T + 6, cy + 4, 4, 1, L.METAL[1])
		L.rect(im, 5 * T + 6, cy, 1, 5, L.METAL[2])
		L.rect(im, 5 * T + 9, cy, 1, 5, L.METAL[1])
		L.rect(im, 5 * T + 7, cy + 5, 2, 3, L.METAL[2])
		L.px(im, 5 * T + 7, cy + 5, L.METAL[4])
	# 6-7 diagonal braces
	for i in T:
		for w in 3:
			L.px(im, 6 * T + i, oy + clampi(i + w - 1, 0, 15), L.WOOD[2] if w == 1 else L.WOOD[1])
			L.px(im, 7 * T + 15 - i, oy + clampi(i + w - 1, 0, 15), L.WOOD[2] if w == 1 else L.WOOD[1])
	# 8-9 hanging stalactites (hang from the top of the cell)
	_drip(im, 8 * T, oy, [Vector3(4, 4, 9), Vector3(10, 3, 6), Vector3(13, 2, 4)])
	_drip(im, 9 * T, oy, [Vector3(7, 5, 13), Vector3(2, 2, 5)])
	# 10 pebbles
	for p in [Vector3(4, 13, 2.2), Vector3(9, 14, 1.6), Vector3(12, 13, 2.0), Vector3(7, 15, 1.2)]:
		L.ellipse(im, 10 * T + p.x, oy + p.y, p.z, p.z * 0.8, L.STONE[4])
		L.px(im, 10 * T + int(p.x) - 1, oy + int(p.y) - 1, L.STONE[6])
	# 11 skull
	var sx := 11 * T
	L.ellipse(im, sx + 8, oy + 11, 3.6, 3.2, Color("#c9c0a8"))
	L.rect(im, sx + 6, oy + 13, 5, 3, Color("#b2a88e"))
	L.px(im, sx + 6, oy + 11, Color("#1a1410"))
	L.px(im, sx + 7, oy + 11, Color("#1a1410"))
	L.px(im, sx + 9, oy + 11, Color("#1a1410"))
	L.px(im, sx + 10, oy + 11, Color("#1a1410"))
	L.px(im, sx + 8, oy + 13, Color("#3a3028"))
	L.px(im, sx + 7, oy + 15, Color("#3a3028"))
	L.px(im, sx + 9, oy + 15, Color("#3a3028"))
	L.px(im, sx + 7, oy + 9, Color("#e8e2d0"))
	L.outline(im, sx, oy, T, T)
	# 12 glow fungus
	var fx := 12 * T
	for m in [Vector3(4, 12, 2.5), Vector3(10, 10, 3.2), Vector3(13, 13, 1.8)]:
		L.rect(im, fx + int(m.x), oy + int(m.y), 1, 16 - int(m.y), Color("#a8b8b0"))
		L.ellipse(im, fx + m.x + 0.5, oy + m.y, m.z, m.z * 0.6, Color("#3ad8c0"))
		L.px(im, fx + int(m.x), oy + int(m.y) - 1, Color("#b8fff0"))
	L.outline(im, fx, oy, T, T)
	# 13 crate
	var cx := 13 * T
	L.rect(im, cx + 1, oy + 3, 14, 13, L.WOOD[2])
	L.rect(im, cx + 1, oy + 3, 14, 2, L.WOOD[4])
	L.rect(im, cx + 1, oy + 14, 14, 2, L.WOOD[1])
	L.line(im, cx + 2, oy + 5, cx + 13, oy + 13, L.WOOD[3])
	L.line(im, cx + 2, oy + 6, cx + 12, oy + 13, L.WOOD[1])
	L.outline(im, cx, oy, T, T)
	# 14 barrel
	var bx := 14 * T
	L.ellipse(im, bx + 8, oy + 9.5, 5.5, 6.5, L.WOOD[3])
	L.rect(im, bx + 3, oy + 4, 11, 12, L.WOOD[3])
	L.rect(im, bx + 3, oy + 4, 3, 12, L.WOOD[4])
	L.rect(im, bx + 11, oy + 4, 3, 12, L.WOOD[2])
	for yy in [5, 10, 14]:
		L.rect(im, bx + 3, oy + yy, 11, 1, L.METAL[2])
	L.outline(im, bx, oy, T, T)
	# 15 cobweb (top-left corner)
	var wx := 15 * T
	var web := Color(0.75, 0.75, 0.8, 0.45)
	for i in 4:
		L.line(im, wx, oy, wx + 15 - i * 5, oy + i * 5, web)
	for r in [4, 8, 12]:
		for a in 7:
			var ang := a / 6.0 * PI / 2.0
			L.px(im, wx + int(cos(ang) * r), oy + int(sin(ang) * r), web)


static func _drip(im: Image, ox: int, oy: int, spikes: Array) -> void:
	for s in spikes:
		var cx: float = s.x
		var w: float = s.y
		var h: float = s.z
		L.tri(im, Vector2(ox + cx - w, oy), Vector2(ox + cx + w, oy), Vector2(ox + cx, oy + h), L.STONE[3])
		L.tri(im, Vector2(ox + cx - w, oy), Vector2(ox + cx - 0.5, oy), Vector2(ox + cx, oy + h), L.STONE[4])
	L.outline(im, ox, oy, T, T)
