extends RefCounted
## Synthesizes sound effects and an ambient music loop as 16-bit mono WAV files.

const RATE := 22050


static func generate() -> void:
	_save("jump", _sweep(0.13, 260.0, 720.0, 0.25, 0.35))
	_save("stomp", _mix(_sweep(0.16, 220.0, 50.0, 0.5, 0.55), _noise(0.12, 0.35, 0.6)))
	_save("hurt", _mix(_sweep(0.32, 520.0, 110.0, 0.5, 0.4, 28.0), _noise(0.2, 0.2, 0.3)))
	_save("gem", _seq([[1046.5, 0.05], [1568.0, 0.11]], 0.5, 0.28))
	_save("heart", _seq([[523.25, 0.06], [659.25, 0.06], [783.99, 0.06], [1046.5, 0.14]], 0.5, 0.28))
	_save("checkpoint", _bell([[659.25, 0.0], [987.77, 0.12], [1318.5, 0.24]], 1.2, 0.35))
	_save("land", _noise(0.06, 0.25, 0.85))
	_save("rock", _mix(_noise(0.45, 0.4, 0.92), _sweep(0.3, 120.0, 40.0, 0.5, 0.3)))
	_save("die", _seq([[392.0, 0.1], [311.1, 0.1], [261.6, 0.1], [196.0, 0.3]], 0.5, 0.3))
	_save("clear", _seq([[523.25, 0.11], [659.25, 0.11], [783.99, 0.11], [1046.5, 0.11], [783.99, 0.11], [1046.5, 0.5]], 0.5, 0.3))
	_save("select", _seq([[880.0, 0.04]], 0.5, 0.2))
	_save("confirm", _seq([[880.0, 0.05], [1318.5, 0.09]], 0.5, 0.25))
	_save("swoop", _sweep(0.25, 900.0, 300.0, 0.5, 0.12, 0.0, true))
	_save("music", _music())


static func _save(name: String, s: PackedFloat32Array) -> void:
	var path := "res://assets/sfx/%s.wav" % name
	var n := s.size()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + path)
		return
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + n * 2)
	f.store_buffer("WAVE".to_ascii_buffer())
	f.store_buffer("fmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(RATE)
	f.store_32(RATE * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(n * 2)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32000.0))
	f.store_buffer(bytes)
	f.close()
	print("  wrote ", path)


static func _square(phase: float, duty: float) -> float:
	return 1.0 if fposmod(phase, 1.0) < duty else -1.0


## Pitch sweep with a square (or sine) oscillator and a decaying envelope.
static func _sweep(dur: float, f0: float, f1: float, duty: float, vol: float, vib: float = 0.0, sine: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		if vib > 0.0:
			f *= 1.0 + 0.06 * sin(i / float(RATE) * vib * TAU)
		phase += f / RATE
		var env := (1.0 - t) * minf(1.0, i / 60.0)
		var v := sin(phase * TAU) if sine else _square(phase, duty)
		out[i] = v * env * vol
	return out


static func _noise(dur: float, vol: float, smooth: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var y := 0.0
	for i in n:
		var t := float(i) / n
		y = lerpf(rng.randf_range(-1.0, 1.0), y, smooth)
		out[i] = y * vol * (1.0 - t) * (1.0 - t) * 2.0
	return out


## Sequence of square-wave notes [[freq, dur], ...].
static func _seq(notes: Array, duty: float, vol: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for nd in notes:
		var n := int(nd[1] * RATE)
		var phase := 0.0
		for i in n:
			var t := float(i) / n
			phase += nd[0] / RATE
			var env := (1.0 - t * 0.7) * minf(1.0, i / 40.0) * minf(1.0, (n - i) / 80.0)
			out.append(_square(phase, duty) * env * vol)
	return out


## Bell-like sine partials [[freq, start_time], ...].
static func _bell(notes: Array, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for nd in notes:
		var start := int(nd[1] * RATE)
		for i in range(start, n):
			var t := (i - start) / float(RATE)
			var env := exp(-t * 4.0) * minf(1.0, (i - start) / 30.0)
			out[i] += (sin(t * nd[0] * TAU) + 0.3 * sin(t * nd[0] * 2.01 * TAU)) * env * vol / notes.size() * 1.6
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


## 24 second seamless ambient loop: low drone, sparse minor bells with echo, water drips.
static func _music() -> PackedFloat32Array:
	var dur := 24.0
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := i / float(RATE)
		var lfo := 0.6 + 0.4 * sin(t / dur * 3.0 * TAU)
		var drone := sin(t * 55.0 * TAU) * 0.16 + sin(t * 82.5 * TAU) * 0.09 * lfo + sin(t * 110.0 * TAU) * 0.035
		out[i] = drone * (0.8 + 0.2 * sin(t / dur * 2.0 * TAU))
	# A minor pentatonic bell motif (A C D E G)
	var motif := [[0.0, 440.0], [1.5, 523.25], [3.0, 659.25], [6.0, 587.33], [7.5, 523.25],
		[9.0, 440.0], [12.0, 392.0], [13.5, 440.0], [15.0, 523.25], [18.0, 659.25],
		[19.5, 783.99], [21.0, 659.25]]
	var bell_len := int(2.5 * RATE)
	for m in motif:
		var start := int(m[0] * RATE)
		for echo in 4:
			var off := start + int(echo * 0.375 * RATE)
			var g := 0.11 * pow(0.45, echo)
			for k in bell_len:
				var tt := k / float(RATE)
				var env := exp(-tt * 2.2) * minf(1.0, k / 60.0)
				var v := sin(tt * m[1] * TAU) + 0.25 * sin(tt * m[1] * 3.0 * TAU) * exp(-tt * 6.0)
				var idx := (off + k) % n
				out[idx] += v * env * g
	# drips
	for d in [2.2, 5.1, 10.7, 14.3, 17.9, 22.6]:
		var start := int(d * RATE)
		for k in int(0.12 * RATE):
			var tt := k / float(RATE)
			var f := 1800.0 - tt * 9000.0
			out[(start + k) % n] += sin(tt * f * TAU) * exp(-tt * 40.0) * 0.08
	return out
