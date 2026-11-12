extends PointLight2D
## Torch/lantern style flicker: layered sines plus occasional random dips.

@export var base_energy := 1.0
@export_range(0.0, 1.0) var flicker := 0.0
@export var speed := 1.0

var _t := 0.0
var _dip := 0.0


func _ready() -> void:
	_t = randf() * 100.0


func _process(delta: float) -> void:
	if flicker <= 0.0:
		energy = base_energy
		return
	_t += delta * speed
	if randf() < 0.02 * speed:
		_dip = randf_range(0.3, 1.0)
	_dip = move_toward(_dip, 0.0, delta * 4.0)
	var n := 0.5 * sin(_t * 7.3) + 0.3 * sin(_t * 13.1 + 1.7) + 0.2 * sin(_t * 23.7 + 0.4)
	energy = base_energy * (1.0 - flicker * (0.5 + 0.5 * n) * 0.6 - flicker * _dip * 0.35)
