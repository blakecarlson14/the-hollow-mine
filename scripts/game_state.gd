extends Node
## Global game state (autoload "Game"): input map, lives/health/score/time, checkpoints, audio.

const START_LIVES := 3
const MAX_HEALTH := 3
const SFX_NAMES := ["jump", "stomp", "hurt", "gem", "heart", "checkpoint", "land", "rock", "die",
	"clear", "select", "confirm", "swoop"]

signal hud_changed

var lives: int = START_LIVES
var health: int = MAX_HEALTH
var score: int = 0
var gems: int = 0
var gems_total: int = 0
var stomps: int = 0
var deaths: int = 0
var time: float = 0.0
var timer_running: bool = false
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_index: int = -1

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	for n in SFX_NAMES:
		var path := "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = load(path)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)
	if ResourceLoader.exists("res://assets/sfx/music.wav"):
		_music.stream = load("res://assets/sfx/music.wav")
		_music.finished.connect(_music.play)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autotest="):
			var scr: GDScript = load("res://tools/autotest.gd")
			if scr == null or not scr.can_instantiate():
				push_error("autotest script failed to load")
				get_tree().quit.call_deferred(2)
				return
			var driver: Node = scr.new()
			driver.scenario = arg.get_slice("=", 1)
			add_child.call_deferred(driver)


func _process(delta: float) -> void:
	if timer_running and not get_tree().paused:
		time += delta


# --------------------------------------------------------------------------- run state

func new_run() -> void:
	lives = START_LIVES
	health = MAX_HEALTH
	score = 0
	gems = 0
	gems_total = 0
	stomps = 0
	deaths = 0
	time = 0.0
	timer_running = false
	checkpoint_index = -1
	checkpoint_pos = Vector2.ZERO
	hud_changed.emit()


func add_score(points: int) -> void:
	score += points
	hud_changed.emit()


func format_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int(fmod(t, 1.0) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]


# --------------------------------------------------------------------------- audio

func sfx(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx.has(name):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _sfx[name]
	p.volume_db = volume_db - 4.0
	p.pitch_scale = pitch
	p.play()


func play_music() -> void:
	if _music.stream and not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


# --------------------------------------------------------------------------- input

func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("jump", [KEY_SPACE, KEY_Z, KEY_K, KEY_W, KEY_UP], [JOY_BUTTON_A], [])
	_bind("accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z], [JOY_BUTTON_A], [])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])


func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.4)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)
	for a in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[0]
		jm.axis_value = a[1]
		InputMap.action_add_event(action, jm)
