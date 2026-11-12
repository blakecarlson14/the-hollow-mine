extends RefCounted
## Builds the TileSet from the generated atlas (see tools/gen_tiles.gd for the layout).
## Physics layer 0 = solid stone (collision layer 1), physics layer 1 = one-way planks (layer 2).
## Interior rock tiles get flipped alternatives (ids 1-3) so the level can break up repetition.

const TEX := preload("res://assets/tiles/tiles.png")
const SOURCE := 0
const FLIPPABLE := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(0, 3)]

static var _cached: TileSet


static func make() -> TileSet:
	if _cached:
		return _cached
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, 2)
	ts.set_physics_layer_collision_mask(1, 0)
	var src := TileSetAtlasSource.new()
	src.texture = TEX
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, SOURCE)
	for y in 4:
		for x in 16:
			var c := Vector2i(x, y)
			src.create_tile(c)
			_configure(src.get_tile_data(c, 0), c)
			if c in FLIPPABLE:
				for alt in [1, 2, 3]:
					src.create_alternative_tile(c, alt)
					var td := src.get_tile_data(c, alt)
					td.flip_h = alt & 1 != 0
					td.flip_v = alt & 2 != 0
					_configure(td, c)
	_cached = ts
	return ts


static func _configure(td: TileData, c: Vector2i) -> void:
	if c.y == 0 or (c.y == 1 and c.x < 8):
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	elif c.y == 1 and c.x >= 8 and c.x <= 11:
		td.add_collision_polygon(1)
		td.set_collision_polygon_points(1, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, -3), Vector2(-8, -3)]))
		td.set_collision_polygon_one_way(1, 0, true)
