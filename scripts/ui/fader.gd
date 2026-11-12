extends CanvasLayer
## Full-screen colour fade used for respawns and scene transitions.

var rect: ColorRect


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.size = Vector2(384, 216)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func fade_to(col: Color, duration: float) -> Signal:
	var tw := create_tween()
	tw.tween_property(rect, "color", col, duration)
	return tw.finished


func set_color(col: Color) -> void:
	rect.color = col
