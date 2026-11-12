extends RefCounted
## Stage 1 "The Hollow Mine" - 420 x 24 tiles. Rows count down from the top (row 0) and
## the usual floor is row 18. Player jump ~3.5 tiles high and ~4.5 tiles long, so steps
## are at most 3 tiles tall and gaps at most 4 tiles wide.


static func build(b) -> void:
	_a_entry(b)
	_b_pits(b)
	_c_climb(b)
	_d_tunnel(b)
	_e_lifts(b)
	_f_crystals(b)
	_g_bridge(b)
	_h_passage(b)
	_i_gauntlet(b)
	_j_exit(b)


static func spikes(b, x0: int, x1: int, top: int) -> void:
	for x in range(x0, x1):
		b.on_ground("spikes", x, top)


# A (0-34): mine entrance - rails, a parked cart, first gems and the first Rustback.
static func _a_entry(b) -> void:
	b.block(0, 0, 2, 24)
	b.ground(0, 20, 19)
	b.ground(20, 34, 17)
	b.start(5, 19)
	b.rails(2, 19, 18)
	b.on_ground("minecart", 10, 19)
	b.frame(7, 13, 10, 19)
	b.at_cell("lantern", 10, 12, {"chain": 24})
	b.gems(14, 19, 18)
	b.frame(24, 30, 11, 17)
	b.at_cell("lantern", 27, 13, {"chain": 24})
	b.on_ground("crawler", 30, 17)
	b.gem_arc(25, 31, 14, 1)


# B (34-70): first pits, a stepping plank, a spike dip and a Shalehop.
static func _b_pits(b) -> void:
	b.ground(37, 44, 17)
	b.plank(45, 47, 15)
	b.at_cell("gem", 45, 14)
	b.at_cell("gem", 46, 14)
	b.ground(48, 56, 18)
	b.on_ground("crawler", 53, 18)
	b.at_cell("lantern", 50, 6)
	b.ground(56, 60, 19)
	spikes(b, 56, 60, 19)
	b.gem_arc(56, 60, 16, 1)
	b.ground(60, 70, 18)
	b.plank(63, 67, 15)
	b.gems(63, 67, 14)
	b.on_ground("hopper", 68, 18)
	b.on_ground("crystal", 61, 18)


# C (70-104): climb planks to a high plateau with checkpoint 1, then drop down.
static func _c_climb(b) -> void:
	b.ground(70, 83, 18)
	b.plank(74, 77, 15)
	b.plank(78, 81, 12)
	b.at_cell("gem", 75, 14)
	b.at_cell("gem", 79, 11)
	b.at_cell("gem", 80, 11)
	b.ground(83, 97, 10)
	b.frame(86, 95, 4, 10)
	b.at_cell("lantern", 90, 6, {"chain": 24})
	b.on_ground("checkpoint", 85, 10)
	b.on_ground("crawler", 93, 10)
	b.gems(88, 92, 9)
	b.ground(97, 104, 18)
	b.at_cell("gem", 98, 13)
	b.at_cell("gem", 98, 15)
	b.at_cell("torch", 101, 15)


# D (100-142): low tunnel with falling stalactites.
static func _d_tunnel(b) -> void:
	b.ground(104, 142, 18)
	b.ceiling(102, 104, 9)
	b.ceiling(104, 138, 12)
	b.ceiling(138, 140, 9)
	b.backwall(103, 9, 139, 18)
	for x in [108, 120, 132]:
		b.at_cell("torch", x, 14)
	for x in [112, 117, 123, 128, 134]:
		b.at_top("rock", x, 12)
	b.on_ground("hopper", 125, 18)
	for x in [110, 115, 120, 126, 131, 136]:
		b.at_cell("gem", x, 17)
	b.at_cell("heart", 140, 17)


# E (142-171): open cavern with a big pit crossed by two lifts and a rock island.
static func _e_lifts(b) -> void:
	# lifts are placed in pixels (centre of the plank top) so they meet the ledges flush
	b.lift_px(Vector2(142 * 16 + 18, 288), Vector2(156 * 16 - 18, 288), 5.0)
	b.ground(156, 159, 16)
	b.lift_px(Vector2(2584, 272), Vector2(2584, 176), 4.0)
	b.ground(164, 171, 12)
	b.at_cell("swooper", 150, 9)
	b.at_cell("swooper", 168, 7)
	b.gems(145, 154, 16, 2)
	b.at_cell("gem", 157, 15)
	b.at_cell("gem", 158, 15)
	b.at_cell("gem", 161, 9)
	b.on_ground("crystal", 157, 16)
	b.at_cell("lantern", 147, 6)
	b.at_cell("lantern", 166, 5)
	b.on_ground("crystal", 169, 12, {"variant": 2})


# F (171-216): checkpoint 2 and the crystal grotto.
static func _f_crystals(b) -> void:
	b.ore_zone(176, 216, "crystal")
	b.ground(171, 182, 18)
	b.on_ground("checkpoint", 175, 18)
	b.ground(182, 187, 17)
	b.ground(187, 191, 15)
	b.ground(194, 200, 16)
	b.ground(200, 207, 14)
	b.ground(207, 216, 17)
	for c in [[184, 17, 0], [189, 15, 1], [196, 16, 2], [205, 14, 0], [209, 17, 1], [215, 17, 2], [180, 18, 1]]:
		b.on_ground("crystal", c[0], c[1], {"variant": c[2]})
	b.on_ground("hopper", 197, 16)
	b.on_ground("crawler", 203, 14)
	b.at_cell("swooper", 211, 10)
	b.gems(188, 191, 13)
	b.gem_arc(191, 194, 13, 1)
	b.gems(201, 207, 12)
	spikes(b, 212, 215, 17)


# G (216-262): rails, then a broken plank bridge over a deep pit.
static func _g_bridge(b) -> void:
	b.ground(216, 223, 18)
	b.rails(216, 223, 17)
	b.on_ground("minecart", 219, 18)
	b.ground(223, 226, 16)
	b.plank(226, 232, 14)
	b.plank(234, 239, 14)
	b.plank(241, 247, 14)
	b.on_ground("crawler", 236, 14)
	b.at_cell("swooper", 240, 9)
	b.at_cell("gem", 232, 12)
	b.at_cell("gem", 233, 12)
	b.at_cell("gem", 239, 12)
	b.at_cell("gem", 240, 12)
	b.at_cell("lantern", 229, 6)
	b.at_cell("lantern", 244, 6)
	b.ground(247, 262, 17)
	b.at_cell("heart", 250, 15)
	b.on_ground("hopper", 257, 17)
	b.frame(249, 256, 10, 17)
	b.at_cell("lantern", 252, 12, {"chain": 24})
	b.gems(253, 256, 16)


# H (262-301): a sunken passage with falling rocks, then a lift over a pit.
static func _h_passage(b) -> void:
	b.ground(262, 266, 17)
	b.ground(266, 281, 19)
	b.ceiling(264, 266, 10)
	b.ceiling(266, 281, 13)
	b.backwall(265, 10, 282, 19)
	for x in [269, 273, 277]:
		b.at_top("rock", x, 13)
	for x in [268, 271, 275, 279]:
		b.at_cell("gem", x, 18)
	b.at_cell("torch", 267, 15)
	b.at_cell("torch", 279, 15)
	b.ground(281, 289, 16)
	b.lift_px(Vector2(289 * 16 + 18, 256), Vector2(301 * 16 - 18, 256), 4.5)
	b.at_cell("swooper", 295, 10)
	b.gems(291, 299, 13, 2)
	b.at_cell("lantern", 286, 7)


# I (301-341): checkpoint 3 and a gauntlet of hoppers, spikes and planks.
static func _i_gauntlet(b) -> void:
	b.ground(301, 313, 16)
	b.on_ground("checkpoint", 304, 16)
	b.at_cell("lantern", 308, 7)
	b.ground(313, 326, 17)
	b.on_ground("hopper", 317, 17)
	spikes(b, 321, 324, 17)
	b.plank(319, 326, 14)
	b.on_ground("crawler", 322, 14)
	b.plank(326, 331, 14)
	b.gems(327, 331, 13)
	b.ground(330, 341, 17)
	b.at_cell("heart", 333, 13)
	b.on_ground("hopper", 335, 17)
	spikes(b, 338, 341, 17)
	b.on_ground("crystal", 331, 17, {"variant": 1})


# J (341-420): final stretch to the exit gate.
static func _j_exit(b) -> void:
	b.ground(341, 353, 17)
	b.on_ground("crawler", 344, 17)
	b.on_ground("crawler", 350, 17)
	b.at_cell("lantern", 347, 7)
	b.ground(356, 363, 15)
	b.at_cell("swooper", 360, 9)
	b.gem_arc(353, 356, 14, 1)
	b.plank(364, 366, 14)
	b.at_cell("gem", 364, 13)
	b.at_cell("gem", 365, 13)
	b.ground(367, 379, 17)
	b.ceiling(367, 379, 11)
	b.backwall(366, 10, 380, 17)
	for x in [370, 374, 377]:
		b.at_top("rock", x, 11)
	b.at_cell("torch", 372, 13)
	b.ground(379, 387, 16)
	b.on_ground("hopper", 383, 16)
	b.ground(390, 420, 18)
	b.block(418, 0, 420, 24)
	b.on_ground("crawler", 397, 18)
	b.at_cell("swooper", 404, 10)
	b.frame(393, 399, 11, 18)
	b.frame(401, 407, 11, 18)
	b.at_cell("lantern", 396, 13, {"chain": 24})
	b.at_cell("lantern", 404, 13, {"chain": 24})
	b.gems(391, 409, 17, 2)
	b.on_ground("crystal", 392, 18, {"variant": 2})
	b.on_ground("goal", 412, 18)
