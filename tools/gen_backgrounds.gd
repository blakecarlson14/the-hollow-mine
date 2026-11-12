extends RefCounted
## Generates horizontally seamless parallax layers:
##   bg0_far.png      distant cavern walls (opaque)
##   bg1_pillars.png  rock pillars and stalactites
##   bg2_scaffold.png distant mine scaffolding with tiny lanterns
##   bg3_supports.png near timber support frames and chains
##   fg_beams.png     dark foreground silhouettes drawn in front of the player

const L := preload("res://tools/art_lib.gd")
const W := 512
const H := 320


static func generate() -> void:
	_far()
	_pillars()
	_scaffold()
	_supports()
	_foreground()


static func _wrap_px(im: Image, x: int, y: int, col: Color) -> void:
	L.px(im, posmod(x, im.get_width()), y, col)


static func _far() -> void:
	var im := L.img(W, H)
	var sky := [Color("#08070d"), Color("#0e0c17"), Color("#151222"), Color("#1c182d"), Color("#231e38")]
	for y in H:
		for x in W:
			var t := float(y) / H
			var b := 1.0 - absf(t - 0.55) * 1.9
			b += (L.fbm(x / 32.0, y / 32.0, 3, 16, 0, 3) - 0.5) * 0.5
			L.px(im, x, y, L.ramp(sky, b * 0.85, x, y))
	# ceiling and floor silhouettes (period 512px = 8 noise cells of 64px)
	var rock := Color("#0a0910")
	var rim := Color("#1d1930")
	for x in W:
		var c := 30.0 + 60.0 * L.fbm(x / 64.0, 0.5, 11, 8, 0, 3)
		var spike := L.h2(x / 6, 0, 12)
		if spike > 0.8:
			c += (spike - 0.8) * 160.0 * (1.0 - absf(posmod(x, 6) - 2.5) / 3.0)
		var f := H - (40.0 + 70.0 * L.fbm(x / 64.0, 3.5, 13, 8, 0, 3))
		var mound := L.h2(x / 9, 1, 14)
		if mound > 0.82:
			f -= (mound - 0.82) * 220.0 * (1.0 - absf(posmod(x, 9) - 4.0) / 4.5)
		for y in H:
			if y < c:
				L.px(im, x, y, rock if y < c - 1 else rim)
			elif y > f:
				L.px(im, x, y, rock if y > f + 1 else rim)
	# faint distant crystal glints
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for i in 40:
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(40, H - 40)
		var col: Color = L.CRYS[2] if rng.randf() > 0.3 else L.VIOLET[2]
		col.a = 0.8
		L.px(im, x, y, col)
		if rng.randf() > 0.6:
			_wrap_px(im, x + 1, y, col.darkened(0.4))
			L.px(im, x, y - 1, col.darkened(0.4))
	L.save(im, "res://assets/bg/bg0_far.png")


static func _pillars() -> void:
	var im := L.img(W, H)
	var pal := [Color("#0f0d17"), Color("#171424"), Color("#201c33"), Color("#2c2745")]
	var centers := [70, 250, 410]
	var widths := [26.0, 40.0, 20.0]
	for i in centers.size():
		var cx: int = centers[i]
		var hw: float = widths[i]
		for y in H:
			var waist := 1.0 - 0.35 * sin(float(y) / H * PI)
			var wob := (L.fbm(y / 12.0, i * 7.0, 21, 0, 0, 2) - 0.5) * 14.0
			var l := cx - hw * waist + wob
			var r := cx + hw * waist + wob * 0.6
			for x in range(int(l), int(r) + 1):
				var u := (x - l) / maxf(r - l, 1.0)
				var v := 0.75 - u * 0.6 + (L.fbm(x / 6.0, y / 6.0, 22, 0, 0, 2) - 0.5) * 0.4
				if x <= int(l) + 1:
					v = 0.95
				_wrap_px(im, x, y, L.ramp(pal, v, x, y))
	# stalactites from the top, mounds + crystals at the bottom
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var x := rng.randf_range(0, W)
		var w := rng.randf_range(4, 12)
		var h := rng.randf_range(20, 70)
		_wrap_tri(im, Vector2(x - w, 0), Vector2(x + w, 0), Vector2(x, h), pal[1])
		_wrap_tri(im, Vector2(x - w, 0), Vector2(x - w * 0.3, 0), Vector2(x, h), pal[2])
	for i in 16:
		var x := rng.randf_range(0, W)
		var w := rng.randf_range(14, 40)
		var h := rng.randf_range(16, 50)
		_wrap_tri(im, Vector2(x - w, H), Vector2(x + w, H), Vector2(x, H - h), pal[1])
		_wrap_tri(im, Vector2(x - w, H), Vector2(x - w * 0.2, H), Vector2(x, H - h), pal[2])
	for i in 9:
		var x := rng.randi_range(0, W - 1)
		var pal2: Array = L.CRYS if i % 3 else L.VIOLET
		for k in 4:
			var bx := x + rng.randi_range(-5, 5)
			var h := rng.randi_range(4, 10)
			_wrap_tri(im, Vector2(bx - 2, H - 18), Vector2(bx + 2, H - 18), Vector2(bx + rng.randi_range(-2, 2), H - 18 - h), pal2[2])
			_wrap_px(im, bx, H - 19 - h + 2, pal2[4])
	L.save(im, "res://assets/bg/bg1_pillars.png")


static func _wrap_tri(im: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	for off in [-W, 0, W]:
		L.tri(im, a + Vector2(off, 0), b + Vector2(off, 0), c + Vector2(off, 0), col)


static func _scaffold() -> void:
	var im := L.img(W, H)
	var wood := Color("#1e1619")
	var hi := Color("#2e2226")
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var posts: Array[int] = []
	for k in 8:
		posts.append(24 + k * 64)
	var deck_y := [150, 225]
	for k in posts.size():
		var x: int = posts[k]
		var top := 120 if k % 3 != 1 else 70
		L.rect(im, x, top, 4, H - top, wood)
		L.rect(im, x, top, 1, H - top, hi)
		var nx: int = posts[(k + 1) % posts.size()] + (W if k == posts.size() - 1 else 0)
		for dy in deck_y:
			if L.h2(k, dy, 9) > 0.3:
				for xx in range(x, nx + 4):
					_wrap_px(im, xx, dy, hi)
					_wrap_px(im, xx, dy + 1, wood)
					_wrap_px(im, xx, dy + 2, wood)
				# railing
				for xx in range(x, nx + 4, 8):
					for yy in range(dy - 8, dy):
						_wrap_px(im, xx, yy, wood)
				for xx in range(x, nx + 4):
					_wrap_px(im, xx, dy - 8, wood)
		# X braces between decks
		if L.h2(k, 1, 10) > 0.4:
			for i in 61:
				var t := i / 60.0
				_wrap_px(im, x + int(t * (nx - x)), int(lerpf(153, 224, t)), wood)
				_wrap_px(im, x + int(t * (nx - x)), int(lerpf(224, 153, t)), wood)
		# ladder
		if L.h2(k, 2, 11) > 0.55:
			var lx := x + 20
			for yy in range(153, 225):
				_wrap_px(im, lx, yy, wood)
				_wrap_px(im, lx + 6, yy, wood)
			for yy in range(156, 225, 5):
				for xx in range(lx, lx + 7):
					_wrap_px(im, xx, yy, hi)
		# tiny lanterns
		if L.h2(k, 3, 12) > 0.25:
			var ly: int = deck_y[k % 2] - 14
			for p in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]:
				var c: Color = L.FIRE[0]
				c.a = 0.55
				_wrap_px(im, x + 6 + p.x, ly + p.y, c)
			_wrap_px(im, x + 6, ly, L.FIRE[3])
			_wrap_px(im, x + 6, ly - 1, L.FIRE[2])
			_wrap_px(im, x + 6, ly + 1, L.FIRE[1])
	# headframe wheel silhouette
	var wc := Vector2(300, 60)
	for a in 64:
		var ang := a / 64.0 * TAU
		L.px(im, int(wc.x + cos(ang) * 18), int(wc.y + sin(ang) * 18), hi)
		L.px(im, int(wc.x + cos(ang) * 17), int(wc.y + sin(ang) * 17), wood)
	for a in 6:
		var ang := a / 6.0 * TAU
		L.line(im, int(wc.x), int(wc.y), int(wc.x + cos(ang) * 17), int(wc.y + sin(ang) * 17), wood)
	L.line(im, 300, 60, 300, 140, wood)
	for i in 60:
		L.px(im, 282 + int(i * 0.3), 60 + i, wood)
		L.px(im, 318 - int(i * 0.3), 60 + i, wood)
	L.save(im, "res://assets/bg/bg2_scaffold.png")


static func _supports() -> void:
	var im := L.img(W, H)
	var wood := [Color("#110b09"), Color("#1d130e"), Color("#2a1b12"), Color("#3a2618")]
	for fx in [60, 316]:
		var gap := 132
		for px_ in [fx, fx + gap]:
			for y in range(40, H):
				for x in range(px_, px_ + 14):
					var v := 0.55 + (L.h2(x, y / 3, 5) - 0.5) * 0.25
					if x == px_:
						v = 0.0
					elif x <= px_ + 2:
						v = 0.95
					elif x >= px_ + 12:
						v = 0.15
					L.px(im, x, y, L.ramp(wood, v, x, y))
		for y in range(30, 46):
			for x in range(fx - 12, fx + gap + 26):
				var v := 0.6 + (L.h2(x / 3, y, 6) - 0.5) * 0.25
				if y <= 31:
					v = 0.95
				elif y >= 44:
					v = 0.0
				L.px(im, x, y, L.ramp(wood, v, x, y))
		# knee braces
		for i in 26:
			for w in 4:
				L.px(im, fx + 14 + i, 46 + 25 - i + w, wood[2] if w < 2 else wood[1])
				L.px(im, fx + gap - i, 46 + 25 - i + w, wood[2] if w < 2 else wood[1])
		# iron straps
		for y in [60, 200]:
			L.rect(im, fx - 1, y, 16, 3, L.METAL[1])
			L.rect(im, fx + gap - 1, y, 16, 3, L.METAL[1])
			L.rect(im, fx - 1, y, 16, 1, L.METAL[2])
			L.rect(im, fx + gap - 1, y, 16, 1, L.METAL[2])
		# hanging chains from the cap
		for cx in [fx + 44, fx + 96]:
			var length := 60 + int(L.h2(cx, 0, 7) * 70)
			for y in range(46, 46 + length):
				var k: int = (y - 46) % 6
				var col: Color = L.METAL[1] if k < 4 else L.METAL[0]
				L.px(im, cx, y, col)
				if k == 0 or k == 3:
					L.px(im, cx - 1, y, L.METAL[1])
					L.px(im, cx + 1, y, L.METAL[1])
			L.rect(im, cx - 2, 46 + length, 5, 2, L.METAL[2])
			L.px(im, cx - 2, 48 + length, L.METAL[2])
			L.px(im, cx - 2, 49 + length, L.METAL[1])
	L.save(im, "res://assets/bg/bg3_supports.png")


static func _foreground() -> void:
	var w := 640
	var h := 384
	var im := L.img(w, h)
	var dark := Color("#040306")
	var edge := Color("#0c0910")
	# one huge timber beam
	for y in h:
		for x in range(300, 326):
			L.px(im, x, y, edge if x == 300 or x == 325 else dark)
	for y in [80, 250]:
		L.rect(im, 298, y, 30, 4, edge)
	# hanging chains
	for c in [Vector2i(110, 120), Vector2i(470, 190), Vector2i(560, 70)]:
		for y in c.y:
			var k: int = y % 8
			if k < 5:
				L.px(im, c.x, y, dark)
				L.px(im, c.x + 3, y, dark)
				if k == 0 or k == 4:
					L.rect(im, c.x, y, 4, 1, dark)
			else:
				L.rect(im, c.x + 1, y, 2, 1, dark)
		L.rect(im, c.x - 1, c.y, 6, 3, dark)
	# stalactites along the top edge
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for i in 14:
		var x := rng.randf_range(0, w)
		var sw := rng.randf_range(6, 18)
		var sh := rng.randf_range(10, 40)
		for off in [-w, 0, w]:
			L.tri(im, Vector2(x - sw + off, 0), Vector2(x + sw + off, 0), Vector2(x + off, sh), dark)
	L.rect(im, 0, 0, w, 4, dark)
	L.save(im, "res://assets/bg/fg_beams.png")
