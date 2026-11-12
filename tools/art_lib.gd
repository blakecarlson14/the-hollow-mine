extends RefCounted
## Shared helpers and palette for the procedural pixel-art generators.
## Everything here is deterministic so re-running the generator gives identical art.

const OUTLINE := Color("#08070c")

# Stone ramp (dark -> light), cold blue-violet.
const STONE := [Color("#1a1724"), Color("#272334"), Color("#363047"), Color("#48405c"),
	Color("#5c5373"), Color("#776d8e"), Color("#968bab")]
const WOOD := [Color("#1e130d"), Color("#2f1d12"), Color("#45291a"), Color("#5f3a22"),
	Color("#7d4f2d"), Color("#9c683b")]
const METAL := [Color("#1b1d22"), Color("#2e3139"), Color("#494d57"), Color("#6d727d"), Color("#9aa0aa")]
const CRYS := [Color("#14304a"), Color("#1f5a85"), Color("#3a9ccc"), Color("#79d8f2"), Color("#d4fbff")]
const VIOLET := [Color("#2a1440"), Color("#4a2470"), Color("#7a44b0"), Color("#b47cf0"), Color("#ead4ff")]
const AMBER := [Color("#5a2208"), Color("#9a4510"), Color("#d9761c"), Color("#ffb347"), Color("#ffe6a0")]
const FIRE := [Color("#a3300f"), Color("#ff7a1f"), Color("#ffc24a"), Color("#fff1b5")]
const RUST := [Color("#2e140c"), Color("#5a2814"), Color("#8f421d"), Color("#c46a32"), Color("#e9a061")]

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func img(w: int, h: int) -> Image:
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


static func px(im: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, col)


static func get_px(im: Image, x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		return im.get_pixel(x, y)
	return Color(0, 0, 0, 0)


## Alpha-blend col over the existing pixel.
static func blend(im: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		var dst := im.get_pixel(x, y)
		im.set_pixel(x, y, dst.blend(col))


static func rect(im: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(im, xx, yy, col)


static func ellipse(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for y in range(floori(cy - ry) - 1, ceili(cy + ry) + 1):
		for x in range(floori(cx - rx) - 1, ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(im, x, y, col)


static func line(im: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(im, x0, y0, col)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


static func tri(im: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var minx := floori(min(a.x, b.x, c.x))
	var maxx := ceili(max(a.x, b.x, c.x))
	var miny := floori(min(a.y, b.y, c.y))
	var maxy := ceili(max(a.y, b.y, c.y))
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var d1 := _sign(p, a, b)
			var d2 := _sign(p, b, c)
			var d3 := _sign(p, c, a)
			var neg := d1 < 0 or d2 < 0 or d3 < 0
			var pos := d1 > 0 or d2 > 0 or d3 > 0
			if not (neg and pos):
				px(im, x, y, col)


static func _sign(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)


## Adds a 1px dark outline around opaque pixels, restricted to a region (one sprite frame).
static func outline(im: Image, rx: int, ry: int, rw: int, rh: int, col: Color = OUTLINE) -> void:
	var pts: Array[Vector2i] = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in range(ry, ry + rh):
		for x in range(rx, rx + rw):
			if im.get_pixel(x, y).a > 0.1:
				continue
			for d in dirs:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= rx and ny >= ry and nx < rx + rw and ny < ry + rh and im.get_pixel(nx, ny).a > 0.5:
					pts.append(Vector2i(x, y))
					break
	for p in pts:
		im.set_pixel(p.x, p.y, col)


# --------------------------------------------------------------------------- noise

static func h2(ix: int, iy: int, s: int) -> float:
	var n: int = ix * 374761393 + iy * 668265263 + s * 982451653
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


## 2D value noise, optionally periodic in x and/or y (period in noise units).
static func vnoise(x: float, y: float, s: int, px_: int = 0, py_: int = 0) -> float:
	var ix := floori(x)
	var iy := floori(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var x0 := ix
	var x1 := ix + 1
	var y0 := iy
	var y1 := iy + 1
	if px_ > 0:
		x0 = posmod(x0, px_)
		x1 = posmod(x1, px_)
	if py_ > 0:
		y0 = posmod(y0, py_)
		y1 = posmod(y1, py_)
	var a := h2(x0, y0, s)
	var b := h2(x1, y0, s)
	var c := h2(x0, y1, s)
	var d := h2(x1, y1, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func fbm(x: float, y: float, s: int, px_: int = 0, py_: int = 0, octaves: int = 3) -> float:
	var v := 0.0
	var amp := 0.5
	var f := 1
	var tot := 0.0
	for o in octaves:
		v += vnoise(x * f, y * f, s + o * 17, px_ * f, py_ * f) * amp
		tot += amp
		amp *= 0.5
		f *= 2
	return v / tot


static func dither(x: int, y: int) -> float:
	return (BAYER[posmod(y, 4) * 4 + posmod(x, 4)] + 0.5) / 16.0


## Pick a colour from a ramp for a continuous value 0..1 using ordered dithering.
static func ramp(pal: Array, v: float, x: int, y: int) -> Color:
	v = clampf(v, 0.0, 0.9999) * (pal.size() - 1)
	var i := floori(v)
	var f := v - i
	if f > dither(x, y) and i + 1 < pal.size():
		i += 1
	return pal[i]


static func save(im: Image, path: String) -> void:
	var err := im.save_png(path)
	if err != OK:
		push_error("Failed to save %s (%d)" % [path, err])
	else:
		print("  wrote ", path)
