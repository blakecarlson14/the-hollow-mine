@tool
extends Node2D
## Draws text with the generated 5x7 pixel font (assets/ui/font.png, ASCII 32-95).

const FONT := preload("res://assets/ui/font.png")

@export_multiline var text := "":
	set(v):
		text = v
		queue_redraw()
@export var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()
@export var shadow := Color(0.02, 0.01, 0.04, 0.9):
	set(v):
		shadow = v
		queue_redraw()
@export_range(1, 8) var size := 1:
	set(v):
		size = v
		queue_redraw()
@export_enum("Left", "Center", "Right") var align := 0:
	set(v):
		align = v
		queue_redraw()


static func text_width(s: String, px_size: int = 1) -> int:
	return maxi(0, s.length() * 6 * px_size - px_size)


func _draw() -> void:
	var lines := text.to_upper().split("\n")
	for li in lines.size():
		var line: String = lines[li]
		var w := text_width(line, size)
		var x0 := 0
		if align == 1:
			x0 = -w / 2
		elif align == 2:
			x0 = -w
		var y := li * 10 * size
		for i in line.length():
			var code := line.unicode_at(i) - 32
			if code <= 0 or code >= 64:
				continue
			var src := Rect2((code % 16) * 6, (code / 16) * 8, 6, 8)
			var dst := Rect2(x0 + i * 6 * size, y, 6 * size, 8 * size)
			if shadow.a > 0.0:
				draw_texture_rect_region(FONT, Rect2(dst.position + Vector2(size, size), dst.size), src, shadow)
			draw_texture_rect_region(FONT, dst, src, color)
