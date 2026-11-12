extends RefCounted
## Generates character, enemy, item and prop sprite sheets (all original designs).

const L := preload("res://tools/art_lib.gd")

const BRASS := [Color("#5c4012"), Color("#9a7020"), Color("#d4a537"), Color("#f5d77a")]
const COAT := [Color("#10262b"), Color("#1c3f45"), Color("#2c5f63"), Color("#46857f")]
const SCARF := [Color("#5a1218"), Color("#9c2228"), Color("#d4413a")]
const SKIN := [Color("#6b3a2a"), Color("#b06a48"), Color("#e0a07a")]
const PANTS := [Color("#16161f"), Color("#2c2c3e")]
const BOOTS := [Color("#24130b"), Color("#4a2a17")]
const HAIR := Color("#2a1a12")


static func generate() -> void:
	_player()
	_crawler()
	_hopper()
	_swooper()
	_items()
	_props()


# =========================================================================== player
# "Wick": a young miner with a brass helmet lamp, teal long coat and red scarf.
# 12 frames of 16x24: 0-1 idle, 2-7 run, 8 jump, 9 fall, 10 hurt, 11 dead

static func _player() -> void:
	var W := 16
	var H := 24
	var im := L.img(W * 12, H)
	var poses: Array = []
	poses.append({})
	poses.append({"bob": 1, "scarf": 1})
	for i in 6:
		var t := i * TAU / 6.0
		poses.append({
			"leg_a": Vector2i(roundi(2.5 * sin(t)), 1 if cos(t) > 0.2 else 0),
			"leg_b": Vector2i(roundi(2.5 * sin(t + PI)), 1 if cos(t + PI) > 0.2 else 0),
			"bob": -1 if absf(sin(t)) < 0.6 else 0,
			"arm_f": Vector2i(-roundi(2.0 * sin(t)), 0),
			"arm_b": Vector2i(roundi(2.0 * sin(t)), 0),
			"lean": 1, "scarf": i % 3,
		})
	poses.append({"leg_a": Vector2i(2, 2), "leg_b": Vector2i(-1, 1), "arm_f": Vector2i(2, -7),
		"arm_b": Vector2i(-2, -6), "bob": -1, "scarf": 2})
	poses.append({"leg_a": Vector2i(2, 1), "leg_b": Vector2i(-2, 0), "arm_f": Vector2i(3, -5),
		"arm_b": Vector2i(-3, -5), "scarf": 3})
	poses.append({"leg_a": Vector2i(2, 1), "leg_b": Vector2i(-2, 1), "arm_f": Vector2i(2, -7),
		"arm_b": Vector2i(-3, -6), "lean": -1, "eye": "x", "scarf": 1})
	poses.append({"leg_a": Vector2i(2, 2), "leg_b": Vector2i(-2, 2), "arm_f": Vector2i(3, -7),
		"arm_b": Vector2i(-3, -7), "eye": "x", "scarf": 2})
	for i in poses.size():
		_miner(im, i * W, 0, poses[i])
		L.outline(im, i * W, 0, W, H)
	L.save(im, "res://assets/sprites/player.png")
	# Window icon: idle frame scaled up on a dark disc.
	var icon := L.img(64, 64)
	L.ellipse(icon, 32, 32, 31, 31, Color("#141020"))
	L.ellipse(icon, 32, 32, 29, 29, Color("#211a33"))
	var f := im.get_region(Rect2i(0, 0, W, H))
	f.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
	icon.blend_rect(f, Rect2i(0, 0, W * 2, H * 2), Vector2i(16, 9))
	L.save(icon, "res://assets/icon.png")


static func _miner(im: Image, ox: int, oy: int, p: Dictionary) -> void:
	var bob: int = p.get("bob", 0)
	var lean: int = p.get("lean", 0)
	var la: Vector2i = p.get("leg_a", Vector2i.ZERO)
	var lb: Vector2i = p.get("leg_b", Vector2i.ZERO)
	var af: Vector2i = p.get("arm_f", Vector2i.ZERO)
	var ab: Vector2i = p.get("arm_b", Vector2i.ZERO)
	var scarf: int = p.get("scarf", 0)
	var eye: String = p.get("eye", "open")
	var u := oy + bob
	var lx := ox + lean

	# back arm (behind body)
	_limb(im, lx + 6, u + 13, lx + 6 + ab.x, u + 17 + ab.y, COAT[0], SKIN[0])
	# legs
	_leg(im, ox + 5 + lb.x, oy, lb.y, PANTS[0], BOOTS[0])
	_leg(im, ox + 8 + la.x, oy, la.y, PANTS[1], BOOTS[1])
	# scarf tail flutters behind
	var tail := [Vector2i(4, 12), Vector2i(3, 13), Vector2i(2, 13 + scarf % 2), Vector2i(1, 14 + (scarf / 2) % 2)]
	for i in tail.size():
		L.px(im, lx + tail[i].x, u + tail[i].y, SCARF[1] if i < 2 else SCARF[0])
	# coat
	for y in range(13, 19):
		for x in range(5, 11):
			var col: Color = COAT[1]
			if x >= 9:
				col = COAT[2]
			if x == 5:
				col = COAT[0]
			L.px(im, lx + x, u + y, col)
	L.px(im, lx + 10, u + 14, COAT[3])
	L.px(im, lx + 10, u + 15, COAT[3])
	for x in range(4, 11):
		L.px(im, lx + x, u + 19, COAT[0] if x < 8 else COAT[1])
	L.px(im, lx + 4, u + 18, COAT[0])
	# belt + buckle
	for x in range(5, 11):
		L.px(im, lx + x, u + 17, L.WOOD[2])
	L.px(im, lx + 8, u + 17, BRASS[3])
	# scarf wrap
	for x in range(5, 11):
		L.px(im, lx + x, u + 12, SCARF[1])
	L.px(im, lx + 7, u + 12, SCARF[2])
	L.px(im, lx + 8, u + 12, SCARF[2])
	# face
	for y in range(8, 12):
		for x in range(5, 11):
			L.px(im, lx + x, u + y, SKIN[1])
	L.px(im, lx + 10, u + 8, SKIN[2])
	L.px(im, lx + 11, u + 10, SKIN[1])
	L.px(im, lx + 6, u + 9, SKIN[0])
	for y in range(8, 11):
		L.px(im, lx + 4, u + y, HAIR)
		L.px(im, lx + 5, u + y, HAIR)
	L.px(im, lx + 5, u + 11, SKIN[0])
	if eye == "x":
		L.px(im, lx + 9, u + 9, Color("#1a1010"))
		L.px(im, lx + 8, u + 8, Color("#1a1010"))
		L.px(im, lx + 10, u + 10, Color("#1a1010"))
	else:
		L.px(im, lx + 9, u + 9, Color("#1a1010"))
		L.px(im, lx + 9, u + 8, HAIR)
		L.px(im, lx + 10, u + 8, HAIR)
	L.px(im, lx + 9, u + 11, SKIN[0])
	# helmet
	for x in range(6, 10):
		L.px(im, lx + x, u + 3, BRASS[2])
	for x in range(5, 11):
		L.px(im, lx + x, u + 4, BRASS[2])
	L.px(im, lx + 6, u + 4, BRASS[3])
	L.px(im, lx + 7, u + 4, BRASS[3])
	for y in range(5, 7):
		for x in range(4, 12):
			L.px(im, lx + x, u + y, BRASS[2] if (x > 5 and x < 9 and y == 5) else BRASS[1])
	L.px(im, lx + 5, u + 5, BRASS[3])
	for x in range(3, 13):
		L.px(im, lx + x, u + 7, BRASS[0])
	# helmet lamp
	L.px(im, lx + 11, u + 4, L.METAL[2])
	L.px(im, lx + 11, u + 5, L.METAL[2])
	L.px(im, lx + 12, u + 4, L.FIRE[3])
	L.px(im, lx + 12, u + 5, L.FIRE[2])
	# front arm
	_limb(im, lx + 8, u + 13, lx + 8 + af.x, u + 17 + af.y, COAT[2], SKIN[1])


static func _limb(im: Image, x0: int, y0: int, x1: int, y1: int, col: Color, hand: Color) -> void:
	L.line(im, x0, y0, x1, y1, col)
	L.line(im, x0 + 1, y0, x1 + 1, y1, col)
	L.px(im, x1, y1 + (1 if y1 >= y0 else -1), hand)
	L.px(im, x1 + 1, y1 + (1 if y1 >= y0 else -1), hand)


static func _leg(im: Image, x: int, oy: int, lift: int, pants: Color, boot: Color) -> void:
	for y in range(19, 22 - lift):
		L.px(im, x, oy + y, pants)
		L.px(im, x + 1, oy + y, pants)
	var by := 22 - lift
	for xx in range(x, x + 3):
		L.px(im, xx, oy + by, boot)
		L.px(im, xx, oy + by + 1, boot)
	L.px(im, x + 2, oy + by, boot.lightened(0.15))


# =========================================================================== enemies
# Rustback: a dome-shelled scrap crawler with a single ember eye. 16x12, frames 0-3 walk, 4 squashed

static func _crawler() -> void:
	var W := 16
	var H := 12
	var im := L.img(W * 5, H)
	for f in 5:
		var ox := f * W
		if f == 4:
			L.ellipse(im, ox + 8, 10.5, 7.5, 1.8, L.RUST[2])
			L.rect(im, ox + 2, 10, 12, 1, L.RUST[3])
			L.px(im, ox + 5, 10, L.METAL[4])
			L.px(im, ox + 11, 10, L.METAL[4])
			L.rect(im, ox + 1, 11, 14, 1, L.RUST[0])
		else:
			var lift := 1 if f % 2 == 1 else 0
			for i in 3:
				var lxp := ox + 4 + i * 3 + ((f + i) % 2)
				L.px(im, lxp, 10, L.METAL[1])
				L.px(im, lxp + (1 if (f + i) % 2 == 0 else -1), 11, L.METAL[1])
			L.rect(im, ox + 3, 8 - lift, 10, 2, Color("#2a1410"))
			var cx := ox + 7.5
			var cy := 8.5 - lift
			for y in range(1, 9 - lift):
				for x in range(ox + 1, ox + 14):
					var dx := (x + 0.5 - cx) / 6.5
					var dy := (y + 0.5 - cy) / 6.5
					if dx * dx + dy * dy <= 1.0:
						var light := 1.0 - Vector2(x - (ox + 5), y - 2).length() / 9.0
						L.px(im, x, y, L.ramp(L.RUST, 0.25 + light * 0.75, x, y))
			for y in range(3 - lift, 8 - lift):
				L.px(im, ox + 7, y, L.RUST[1])
			L.px(im, ox + 4, 6 - lift, L.METAL[4])
			L.px(im, ox + 10, 6 - lift, L.METAL[4])
			L.px(im, ox + 7, 2 - lift, L.METAL[3])
			# head + ember eye
			L.rect(im, ox + 12, 6 - lift, 3, 4, L.METAL[1])
			L.px(im, ox + 13, 7 - lift, Color("#ff6a3a"))
			L.px(im, ox + 14, 7 - lift, Color("#ffd8a8"))
			L.px(im, ox + 15, 9 - lift, L.METAL[2])
		L.outline(im, ox, 0, W, H)
	L.save(im, "res://assets/sprites/crawler.png")


# Shalehop: a squat slate creature with crystal shards on its back. 16x16
# frames: 0 idle, 1 crouch, 2 rise, 3 fall, 4 squashed
static func _hopper() -> void:
	var W := 16
	var H := 16
	var im := L.img(W * 5, H)
	var body := [Vector4(8, 11, 6.5, 4.5), Vector4(8, 12.5, 7.5, 3.5), Vector4(8, 8, 5.0, 6.0),
		Vector4(8, 9.5, 6.0, 5.0), Vector4(8, 14, 7.5, 2.0)]
	var slate := [Color("#1c1726"), Color("#342b48"), Color("#52456c"), Color("#75669a"), Color("#9a8cbe")]
	for f in 5:
		var ox := f * W
		var b: Vector4 = body[f]
		if f == 2 or f == 3:
			L.rect(im, ox + 4, int(b.y + b.w) - 1, 2, 16 - int(b.y + b.w) + 1, slate[1])
			L.rect(im, ox + 10, int(b.y + b.w) - 1, 2, 16 - int(b.y + b.w) + 1, slate[1])
		else:
			L.rect(im, ox + 3, 15, 3, 1, slate[1])
			L.rect(im, ox + 10, 15, 3, 1, slate[1])
		for y in H:
			for x in range(ox, ox + W):
				var dx := (x + 0.5 - (ox + b.x)) / b.z
				var dy := (y + 0.5 - b.y) / b.w
				if dx * dx + dy * dy <= 1.0:
					var shade := 0.9 - (dy + 1.0) * 0.3 - dx * 0.15
					L.px(im, x, y, L.ramp(slate, shade, x, y))
		# belly
		for x in range(int(b.x - b.z * 0.6), int(b.x + b.z * 0.6) + 1):
			L.px(im, ox + x, int(b.y + b.w * 0.55), slate[3])
		if f != 4:
			# crystals on back
			var top := b.y - b.w
			L.tri(im, Vector2(ox + b.x - 4, top + 3), Vector2(ox + b.x - 1, top + 2), Vector2(ox + b.x - 4, top - 3), L.CRYS[2])
			L.tri(im, Vector2(ox + b.x - 1, top + 2), Vector2(ox + b.x + 2, top + 2), Vector2(ox + b.x, top - 4), L.CRYS[3])
			L.px(im, ox + int(b.x), int(top - 2), L.CRYS[4])
			L.px(im, ox + int(b.x - 4), int(top - 1), L.CRYS[4])
			# eyes
			var ey := int(b.y - b.w * 0.3)
			L.px(im, ox + int(b.x + 2), ey, Color("#f4f0a0"))
			L.px(im, ox + int(b.x + 4), ey, Color("#f4f0a0"))
			L.px(im, ox + int(b.x + 3), ey + 2, slate[0])
			L.px(im, ox + int(b.x + 4), ey + 2, slate[0])
		else:
			L.px(im, ox + 6, 13, L.CRYS[2])
			L.px(im, ox + 9, 13, L.CRYS[3])
		L.outline(im, ox, 0, W, H)
	L.save(im, "res://assets/sprites/hopper.png")


# Gloomwing: a moth-like cave flyer with a glowing lantern abdomen. 24x16
# frames: 0-2 flap, 3 dive, 4 dead
static func _swooper() -> void:
	var W := 24
	var H := 16
	var im := L.img(W * 5, H)
	var tips := [Vector2(2, 0), Vector2(0, 7), Vector2(3, 14), Vector2(6, 2), Vector2(2, 11)]
	var membrane := [Color("#1e1828"), Color("#2b2236"), Color("#3e3250"), Color("#5a4a70")]
	for f in 5:
		var ox := f * W
		var t: Vector2 = tips[f]
		for side in [-1, 1]:
			var sh := Vector2(ox + 12 + side * 2, 6)
			var sh2 := Vector2(ox + 12 + side * 2, 10)
			var tip := Vector2(ox + 12 + side * (12 - t.x), t.y)
			L.tri(im, sh, sh2, tip, membrane[1])
			L.tri(im, sh, sh.lerp(sh2, 0.5), tip, membrane[2])
			L.line(im, int(sh.x), int(sh.y), int(tip.x), int(tip.y), membrane[3])
			# tattered edge
			for k in 4:
				var q := sh2.lerp(tip, 0.25 + k * 0.2)
				L.px(im, int(q.x), int(q.y), Color(0, 0, 0, 0))
		# abdomen lantern
		var glow := [Color("#4f7a28"), Color("#8fd14f"), Color("#d8ff8a"), Color("#f6ffe0")]
		if f == 4:
			glow = [Color("#2a3320"), Color("#3e4a2c"), Color("#556040"), Color("#6a7650")]
		L.ellipse(im, ox + 12, 10, 2.6, 4.0, glow[1])
		L.ellipse(im, ox + 11.6, 9.6, 1.6, 2.8, glow[2])
		L.px(im, ox + 11, 9, glow[3])
		L.px(im, ox + 11, 11, glow[0])
		L.px(im, ox + 12, 12, glow[0])
		# head
		L.ellipse(im, ox + 12, 5, 2.4, 2.0, Color("#2a2030"))
		var eye := Color("#ff4a5a") if f != 4 else Color("#40202a")
		L.px(im, ox + 11, 5, eye)
		L.px(im, ox + 13, 5, eye)
		L.line(im, ox + 11, 3, ox + 9, 0, Color("#8a7a9a"))
		L.line(im, ox + 13, 3, ox + 15, 0, Color("#8a7a9a"))
		L.outline(im, ox, 0, W, H)
	L.save(im, "res://assets/sprites/swooper.png")


# =========================================================================== items + ui

static func _items() -> void:
	# ember-ore gem, 8x8 x 4 spin frames
	var gem := L.img(32, 8)
	var widths := [3.6, 2.4, 1.0, 2.4]
	for f in 4:
		var ox := f * 8
		var w: float = widths[f]
		for y in 8:
			var hw := w * (1.0 - absf(y - 3.5) / 4.0)
			for x in 8:
				var dx := x + 0.5 - 4.0
				if absf(dx) <= hw + 0.01:
					var col: Color = L.AMBER[3] if dx < 0 else L.AMBER[2]
					if f == 3:
						col = L.AMBER[2] if dx < 0 else L.AMBER[3]
					if y <= 1:
						col = L.AMBER[4]
					if y >= 6:
						col = L.AMBER[1]
					L.px(gem, ox + x, y, col)
		if f == 0:
			L.px(gem, ox + 3, 2, Color.WHITE)
		L.outline(gem, ox, 0, 8, 8, Color("#2a1004"))
	L.save(gem, "res://assets/sprites/gem.png")

	# ui icons 8x8: 0 heart, 1 heart empty, 2 life (helmet), 3 gem, 4 clock, 5 cursor
	var ui := L.img(48, 8)
	var heart := [".##.##..", "#######.", "#######.", ".#####..", "..###...", "...#....", "........", "........"]
	for y in 8:
		for x in 8:
			if heart[y][x] == "#":
				L.px(ui, x, y + 1, Color("#d4413a") if not (x == 1 and y == 1) else Color("#ffb0a0"))
				L.px(ui, 8 + x, y + 1, Color("#3a2030"))
	L.px(ui, 2, 2, Color("#ffd0c0"))
	L.outline(ui, 0, 0, 8, 8)
	L.outline(ui, 8, 0, 8, 8)
	L.rect(ui, 18, 2, 4, 1, BRASS[2])
	L.rect(ui, 17, 3, 6, 2, BRASS[1])
	L.rect(ui, 16, 5, 8, 1, BRASS[0])
	L.px(ui, 23, 3, L.FIRE[3])
	L.rect(ui, 18, 6, 4, 2, SKIN[1])
	L.outline(ui, 16, 0, 8, 8)
	ui.blit_rect(gem, Rect2i(0, 0, 8, 8), Vector2i(24, 0))
	L.ellipse(ui, 36, 4, 3.4, 3.4, Color("#c8c8d8"))
	L.ellipse(ui, 36, 4, 2.4, 2.4, Color("#2a2838"))
	L.px(ui, 36, 2, Color.WHITE)
	L.px(ui, 36, 3, Color.WHITE)
	L.px(ui, 37, 4, Color.WHITE)
	L.outline(ui, 32, 0, 8, 8)
	L.tri(ui, Vector2(41, 0.5), Vector2(41, 7.5), Vector2(46, 4), L.FIRE[2])
	L.save(ui, "res://assets/ui/icons.png")

	# heart pickup 10x10
	var hp := L.img(10, 10)
	for y in 8:
		for x in 8:
			if heart[y][x] == "#":
				L.px(hp, x + 1, y + 1, Color("#e0503f"))
	L.px(hp, 3, 2, Color("#ffd0c0"))
	L.px(hp, 2, 3, Color("#ffb0a0"))
	L.outline(hp, 0, 0, 10, 10)
	L.save(hp, "res://assets/sprites/heart.png")


# =========================================================================== props

static func _props() -> void:
	# hanging lantern 8x14 x 3 flicker frames
	var lan := L.img(24, 14)
	for f in 3:
		var ox := f * 8
		L.px(lan, ox + 3, 0, L.METAL[2])
		L.px(lan, ox + 4, 0, L.METAL[2])
		L.px(lan, ox + 3, 1, L.METAL[1])
		L.rect(lan, ox + 2, 2, 4, 1, L.METAL[2])
		L.rect(lan, ox + 1, 3, 6, 1, L.METAL[3])
		L.rect(lan, ox + 1, 4, 6, 7, L.AMBER[3])
		L.rect(lan, ox + 2, 4, 4, 7, L.FIRE[2])
		var fh: int = [3, 4, 2][f]
		L.rect(lan, ox + 3, 9 - fh, 2, fh + 1, L.FIRE[3])
		L.px(lan, ox + 3 + (f % 2), 8 - fh, Color.WHITE)
		L.rect(lan, ox + 1, 4, 1, 7, L.METAL[1])
		L.rect(lan, ox + 6, 4, 1, 7, L.METAL[1])
		L.rect(lan, ox + 1, 11, 6, 1, L.METAL[3])
		L.rect(lan, ox + 2, 12, 4, 1, L.METAL[1])
		L.px(lan, ox + 3, 13, L.METAL[2])
		L.outline(lan, ox, 0, 8, 14)
	L.save(lan, "res://assets/sprites/lantern.png")

	# wall torch 8x16 x 3
	var tor := L.img(24, 16)
	for f in 3:
		var ox := f * 8
		L.rect(tor, ox + 3, 9, 2, 7, L.WOOD[3])
		L.rect(tor, ox + 4, 9, 1, 7, L.WOOD[2])
		L.rect(tor, ox + 2, 7, 4, 2, L.METAL[2])
		var shapes := [[Vector2(1.5, 7), Vector2(6.5, 7), Vector2(4, 0)], [Vector2(1.5, 7), Vector2(6.5, 7), Vector2(3, 1)],
			[Vector2(1.5, 7), Vector2(6.5, 7), Vector2(5, 1)]]
		var s: Array = shapes[f]
		L.tri(tor, Vector2(ox, 0) + s[0], Vector2(ox, 0) + s[1], Vector2(ox, 0) + s[2], L.FIRE[1])
		L.tri(tor, Vector2(ox + 1, 0) + s[0], Vector2(ox - 1, 0) + s[1], Vector2(ox, 2) + s[2], L.FIRE[2])
		L.rect(tor, ox + 3, 5, 2, 2, L.FIRE[3])
		L.outline(tor, ox, 0, 8, 16)
	L.save(tor, "res://assets/sprites/torch.png")

	# crystal clusters 16x16: 0-1 cyan, 2 violet
	var cr := L.img(48, 16)
	for v in 3:
		var pal: Array = L.VIOLET if v == 2 else L.CRYS
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + v
		var n := 4 + v
		for i in n:
			var bx := rng.randf_range(3.0, 13.0) + v * 16
			var h := rng.randf_range(5.0, 14.0)
			var w := rng.randf_range(1.5, 2.6)
			var lean := rng.randf_range(-3.0, 3.0)
			var tip := Vector2(bx + lean, 16 - h)
			L.tri(cr, Vector2(bx - w, 16), Vector2(bx + w, 16), tip, pal[2])
			L.tri(cr, Vector2(bx - w, 16), Vector2(bx, 16), tip, pal[3])
			L.line(cr, int(bx - w * 0.5), 15, int(tip.x), int(tip.y), pal[4])
		L.outline(cr, v * 16, 0, 16, 16, pal[0])
	L.save(cr, "res://assets/sprites/crystal.png")

	# checkpoint: post with a spirit lantern, 16x32 x 2 (unlit, lit)
	var cp := L.img(32, 32)
	for f in 2:
		var ox := f * 16
		L.rect(cp, ox + 6, 4, 3, 26, L.WOOD[2])
		L.rect(cp, ox + 6, 4, 1, 26, L.WOOD[3])
		L.rect(cp, ox + 8, 4, 1, 26, L.WOOD[1])
		L.rect(cp, ox + 3, 28, 9, 4, L.STONE[3])
		L.rect(cp, ox + 3, 28, 9, 1, L.STONE[5])
		L.rect(cp, ox + 6, 3, 8, 2, L.WOOD[3])
		L.px(cp, ox + 12, 5, L.METAL[2])
		var glass: Array = [Color("#1c2030"), Color("#262c40"), Color("#323a52")] if f == 0 else [L.CRYS[2], L.CRYS[3], L.CRYS[4]]
		L.rect(cp, ox + 10, 6, 5, 1, L.METAL[3])
		L.rect(cp, ox + 10, 7, 5, 6, glass[0])
		L.rect(cp, ox + 11, 7, 3, 6, glass[1])
		L.rect(cp, ox + 12, 8, 1, 4, glass[2])
		L.rect(cp, ox + 10, 13, 5, 1, L.METAL[3])
		L.outline(cp, ox, 0, 16, 32)
	L.save(cp, "res://assets/sprites/checkpoint.png")

	# iron spikes 16x8
	var sp := L.img(16, 8)
	for i in 4:
		var bx := i * 4
		L.tri(sp, Vector2(bx, 6), Vector2(bx + 4, 6), Vector2(bx + 2, 0), L.METAL[2])
		L.tri(sp, Vector2(bx, 6), Vector2(bx + 2, 6), Vector2(bx + 2, 0), L.METAL[3])
		L.px(sp, bx + 2, 0, L.METAL[4])
		L.px(sp, bx + 1, 5, L.RUST[2])
	L.rect(sp, 0, 6, 16, 2, L.METAL[1])
	L.rect(sp, 0, 6, 16, 1, L.METAL[2])
	L.save(sp, "res://assets/sprites/spikes.png")

	# stalactite 12x18
	var st := L.img(12, 18)
	L.tri(st, Vector2(0, 0), Vector2(12, 0), Vector2(6, 18), L.STONE[3])
	L.tri(st, Vector2(0, 0), Vector2(5, 0), Vector2(6, 18), L.STONE[5])
	L.tri(st, Vector2(8, 0), Vector2(12, 0), Vector2(6, 18), L.STONE[2])
	L.line(st, 4, 3, 6, 8, L.STONE[1])
	L.line(st, 7, 2, 6, 5, L.STONE[1])
	L.rect(st, 0, 0, 12, 2, L.STONE[4])
	L.outline(st, 0, 0, 12, 18)
	L.save(st, "res://assets/sprites/stalactite.png")

	# rock bits 4x4 x 4
	var rb := L.img(16, 4)
	for f in 4:
		L.ellipse(rb, f * 4 + 2, 2, 1.6 - f * 0.15, 1.4, L.STONE[4])
		L.px(rb, f * 4 + 1, 1, L.STONE[6])
	L.save(rb, "res://assets/sprites/rockbits.png")

	# lift platform 48x10
	var lift := L.img(48, 10)
	for x in 48:
		L.px(lift, x, 2, L.WOOD[5])
		L.px(lift, x, 3, L.WOOD[4])
		for y in range(4, 7):
			L.px(lift, x, y, L.WOOD[3] if L.h2(x, y, 33) > 0.25 else L.WOOD[2])
		L.px(lift, x, 7, L.WOOD[1])
		if x % 12 == 0:
			for y in range(3, 8):
				L.px(lift, x, y, L.WOOD[1])
	for bx in [3, 42]:
		L.rect(lift, bx, 2, 3, 6, L.METAL[2])
		L.rect(lift, bx, 2, 1, 6, L.METAL[3])
		L.px(lift, bx + 1, 0, L.METAL[3])
		L.px(lift, bx, 1, L.METAL[2])
		L.px(lift, bx + 2, 1, L.METAL[2])
	L.rect(lift, 1, 8, 46, 1, L.WOOD[0])
	L.outline(lift, 0, 0, 48, 10)
	L.save(lift, "res://assets/sprites/lift.png")

	# chain link 4x8 (tiles vertically)
	var ch := L.img(4, 8)
	L.rect(ch, 0, 0, 4, 1, L.METAL[3])
	L.rect(ch, 0, 4, 4, 1, L.METAL[1])
	L.rect(ch, 0, 0, 1, 5, L.METAL[2])
	L.rect(ch, 3, 0, 1, 5, L.METAL[1])
	L.rect(ch, 1, 5, 2, 3, L.METAL[2])
	L.px(ch, 1, 5, L.METAL[4])
	L.save(ch, "res://assets/sprites/chain.png")

	# minecart 28x20 with glowing ore
	var mc := L.img(28, 20)
	for i in 9:
		var gx := 4 + i * 2.4
		L.ellipse(mc, gx, 4, 2.2, 2.0, L.STONE[4] if i % 3 else L.AMBER[3])
	L.px(mc, 8, 2, L.AMBER[4])
	L.px(mc, 18, 3, L.CRYS[3])
	L.px(mc, 19, 2, L.CRYS[4])
	L.tri(mc, Vector2(1, 5), Vector2(27, 5), Vector2(23, 15), L.RUST[2])
	L.tri(mc, Vector2(1, 5), Vector2(23, 15), Vector2(5, 15), L.RUST[2])
	L.rect(mc, 1, 5, 26, 2, L.RUST[3])
	L.rect(mc, 4, 12, 20, 3, L.RUST[1])
	for rx in [5, 11, 17, 23]:
		L.px(mc, rx, 6, L.METAL[4])
	L.line(mc, 9, 7, 9, 13, L.RUST[1])
	L.line(mc, 18, 7, 18, 13, L.RUST[1])
	for wx in [7, 21]:
		L.ellipse(mc, wx, 16.5, 3.2, 3.2, L.METAL[1])
		L.ellipse(mc, wx, 16.5, 1.4, 1.4, L.METAL[3])
	L.outline(mc, 0, 0, 28, 20)
	L.save(mc, "res://assets/sprites/minecart.png")

	# mine exit gate 64x80 - timber frame around a shaft of daylight
	var gt := L.img(64, 80)
	for y in range(8, 80):
		for x in range(10, 54):
			var d := absf(x - 32.0) / 22.0
			var t := y / 80.0
			var v := 1.0 - d * 0.7 - t * 0.15
			var col: Color = L.ramp([Color("#c89048"), Color("#f0c070"), Color("#ffe8b0"), Color("#fffbea")], v, x, y)
			L.px(gt, x, y, col)
	for y in range(8, 80):
		for x in [10, 11, 52, 53]:
			if L.dither(x, y) > 0.5:
				L.px(gt, x, y, Color("#8a6030"))
	for side in [2, 54]:
		for y in range(0, 80):
			for x in range(side, side + 8):
				var col: Color = L.WOOD[2]
				if x == side:
					col = L.WOOD[0]
				elif x == side + 1:
					col = L.WOOD[3]
				elif x == side + 7:
					col = L.WOOD[1]
				L.px(gt, x, y, col)
	for y in range(0, 9):
		for x in range(0, 64):
			var col: Color = L.WOOD[2] if L.h2(x, y, 44) > 0.2 else L.WOOD[1]
			if y == 0:
				col = L.WOOD[0]
			elif y == 1:
				col = L.WOOD[4]
			elif y == 8:
				col = L.WOOD[0]
			L.px(gt, x, y, col)
	for bx in [6, 58]:
		L.rect(gt, bx - 1, 3, 3, 3, L.METAL[2])
		L.px(gt, bx, 4, L.METAL[4])
	L.save(gt, "res://assets/sprites/goal.png")
