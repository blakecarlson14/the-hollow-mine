extends RefCounted
## Builds the Parallax2D background layers (behind the level) and the foreground layer
## (in front of the player). Backgrounds use light_mask 2 so world lights don't touch them;
## their brightness is compensated against the CanvasModulate darkness via modulate.

# path, scroll scale, modulate, z_index
const BACK := [
	["res://assets/bg/bg0_far.png", Vector2(0.06, 0.08), Color(2.9, 2.9, 3.4), -40],
	["res://assets/bg/bg1_pillars.png", Vector2(0.2, 0.25), Color(2.6, 2.6, 3.1), -35],
	["res://assets/bg/bg2_scaffold.png", Vector2(0.38, 0.4), Color(2.4, 2.3, 2.6), -30],
	["res://assets/bg/bg3_supports.png", Vector2(0.6, 0.55), Color(2.0, 1.9, 2.0), -25],
]
const FRONT := ["res://assets/bg/fg_beams.png", Vector2(1.35, 1.0), Color(1, 1, 1, 0.85), 40]


static func build_background(parent: Node) -> Array[Parallax2D]:
	var out: Array[Parallax2D] = []
	for def in BACK:
		var p := _layer(def)
		parent.add_child(p)
		out.append(p)
	return out


static func build_foreground(parent: Node) -> Parallax2D:
	var p := _layer(FRONT)
	parent.add_child(p)
	return p


static func _layer(def: Array) -> Parallax2D:
	var tex: Texture2D = load(def[0])
	var p := Parallax2D.new()
	p.name = "Parallax_" + String(def[0]).get_file().get_basename()
	p.scroll_scale = def[1]
	p.repeat_size = Vector2(tex.get_width(), 0)
	p.repeat_times = 3
	p.z_index = def[3]
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.modulate = def[2]
	s.light_mask = 2
	p.add_child(s)
	return p
