extends SceneTree
## Generates assets/splash.png, the boot splash shown while the game loads (it replaces Godot's logo,
## and the web build's loading screen shows it too). It reuses the far background layers and the pixel
## font, with the title laid out exactly as on the title screen so loading hands off to it seamlessly.
## Needs the backgrounds and font from gen_art.gd. Run on its own with:
##   godot --headless --path . --script res://tools/gen_splash.gd

const L := preload("res://tools/art_lib.gd")

const W := 384
const H := 216
const BG := Color(0.03, 0.025, 0.05)  # project clear colour
const TITLE := Color(1.0, 0.66, 0.26)
const TITLE_SHADOW := Color(0.25, 0.05, 0.08)
const SUB := Color(0.85, 0.8, 1.05)
const SUB_SHADOW := Color(0.02, 0.01, 0.04)


func _init() -> void:
	generate()
	quit()


static func generate() -> void:
	var im := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	im.fill(BG)
	# The background layers, tinted the way the game tints them (each layer's modulate in parallax.gd
	# times the CanvasModulate darkness in atmosphere.gd), then dimmed so the title reads clearly.
	var darkness := Color(0.3, 0.28, 0.4)
	var layers := [
		["bg0_far", Color(2.9, 2.9, 3.4)],
		["bg1_pillars", Color(2.6, 2.6, 3.1)],
		["bg2_scaffold", Color(2.4, 2.3, 2.6)],
		["bg3_supports", Color(2.0, 1.9, 2.0)],
	]
	for layer in layers:
		var src := _load("res://assets/bg/%s.png" % layer[0])
		if src:
			_blit(im, src, Vector2i(64, 104), layer[1] * darkness * 0.8)
	_glow(im, Vector2(192, 52), Vector2(190, 60), Color(1.0, 0.55, 0.2), 0.16)
	_vignette(im)
	var font := _load("res://assets/ui/font.png")
	if font:
		_text(im, font, "HOLLOW MINE", 4, 30, TITLE, TITLE_SHADOW)
		_text(im, font, "A LANTERN-LIT DESCENT", 2, 78, SUB, SUB_SHADOW)
	L.save(im, "res://assets/splash.png")


## Loads a PNG straight from disk, so this works before Godot has imported anything.
static func _load(path: String) -> Image:
	var src := Image.load_from_file(ProjectSettings.globalize_path(path))
	if src == null:
		push_error("Missing %s; run gen_art.gd first" % path)
		return null
	src.convert(Image.FORMAT_RGBA8)
	return src


## Alpha-blends `src` onto `im`, reading `src` from `offset`, multiplied by `tint`.
static func _blit(im: Image, src: Image, offset: Vector2i, tint: Color) -> void:
	for y in H:
		for x in W:
			var sx := x + offset.x
			var sy := y + offset.y
			if sx >= src.get_width() or sy >= src.get_height():
				continue
			var c := src.get_pixel(sx, sy)
			if c.a <= 0.0:
				continue
			var base := im.get_pixel(x, y)
			var lit := Color(c.r * tint.r, c.g * tint.g, c.b * tint.b)
			im.set_pixel(x, y, base.lerp(lit, c.a))


## Soft warm light behind the title, quantised to a few dithered steps to stay pixel-art.
static func _glow(im: Image, center: Vector2, radius: Vector2, col: Color, amount: float) -> void:
	for y in H:
		for x in W:
			var d := Vector2((x - center.x) / radius.x, (y - center.y) / radius.y).length()
			var t := clampf(1.0 - d, 0.0, 1.0)
			t = floorf(t * 4.0 + L.dither(x, y)) / 4.0
			if t > 0.0:
				var base := im.get_pixel(x, y)
				im.set_pixel(x, y, base + Color(col.r, col.g, col.b, 0.0) * amount * t)


static func _vignette(im: Image) -> void:
	for y in H:
		for x in W:
			var d := Vector2((x - W / 2.0) / (W / 2.0), (y - H / 2.0) / (H / 2.0)).length()
			var t := clampf((d - 0.55) / 0.6, 0.0, 1.0)
			im.set_pixel(x, y, im.get_pixel(x, y).lerp(BG, t))


## Draws centred text with the 6x8-cell font atlas (ASCII 32-95, 16 per row), like PixelText does.
static func _text(im: Image, font: Image, s: String, size: int, y: int, col: Color, shadow: Color) -> void:
	var x0 := W / 2 - maxi(0, s.length() * 6 * size - size) / 2
	for pass_i in 2:
		var off := size if pass_i == 0 else 0
		var c := shadow if pass_i == 0 else col
		for i in s.length():
			var code := s.unicode_at(i) - 32
			if code <= 0 or code >= 64:
				continue
			for gy in 8:
				for gx in 6:
					if font.get_pixel((code % 16) * 6 + gx, (code / 16) * 8 + gy).a < 0.5:
						continue
					L.rect(im, x0 + i * 6 * size + gx * size + off, y + gy * size + off, size, size, c)
