extends RefCounted
## Mood and lighting: CanvasModulate darkness, WorldEnvironment glow/bloom,
## camera-following dust motes and embers, and a dithered vignette overlay.

const DOT := preload("res://assets/ui/dot.png")
const SPARK := preload("res://assets/ui/spark.png")

const DARKNESS := Color(0.3, 0.28, 0.4)


static func build(parent: Node, camera: Camera2D) -> void:
	var cm := CanvasModulate.new()
	cm.name = "Darkness"
	cm.color = DARKNESS
	parent.add_child(cm)
	parent.add_child(make_environment())
	camera.add_child(_dust())
	camera.add_child(_embers())
	parent.add_child(make_vignette())


static func make_environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 1.25
	env.glow_strength = 1.05
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.5)
	env.set_glow_level(4, 0.25)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	var we := WorldEnvironment.new()
	we.name = "Environment"
	we.environment = env
	return we


static func _dust() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Dust"
	p.texture = DOT
	p.amount = 70
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(230, 130)
	p.direction = Vector2(1, 0.2)
	p.spread = 180.0
	p.gravity = Vector2(1.5, 2.5)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.z_index = 30
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1.6, 1.5, 1.9, 0.0), Color(1.6, 1.5, 1.9, 0.55),
		Color(1.6, 1.5, 1.9, 0.55), Color(1.6, 1.5, 1.9, 0.0)])
	p.color_ramp = g
	return p


static func _embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Embers"
	p.texture = SPARK
	p.amount = 10
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(230, 40)
	p.position = Vector2(0, 90)
	p.direction = Vector2(0.3, -1)
	p.spread = 30.0
	p.gravity = Vector2(3, -4)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	p.z_index = 30
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	g.colors = PackedColorArray([Color(4.0, 1.8, 0.6, 0.0), Color(4.0, 1.8, 0.6, 1.0),
		Color(3.0, 1.0, 0.4, 0.8), Color(2.0, 0.5, 0.2, 0.0)])
	p.color_ramp = g
	return p


## Full-screen dithered vignette on its own CanvasLayer (not affected by the darkness).
static func make_vignette() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 5
	var w := 384
	var h := 216
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	for y in h:
		for x in w:
			var dx := (x + 0.5 - w * 0.5) / (w * 0.5)
			var dy := (y + 0.5 - h * 0.5) / (h * 0.5)
			var d := sqrt(dx * dx * 0.8 + dy * dy * 1.1)
			var a := clampf((d - 0.62) / 0.6, 0.0, 1.0)
			a = a * a * 0.85
			var th: float = (bayer[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0
			var q := floorf(a * 4.0) / 4.0
			if a * 4.0 - floorf(a * 4.0) > th:
				q += 0.25
			img.set_pixel(x, y, Color(0.01, 0.0, 0.03, q))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size = Vector2(w, h)
	layer.add_child(tr)
	return layer
