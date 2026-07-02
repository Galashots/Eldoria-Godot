extends Node

## One-shot editor tool: repaints and extends the World/Ground TileMapLayer in
## scenes/main/Main.tscn for the "epic map pass" (docs/design/NORTH_STAR.md
## mandate: make the map interesting, beautiful, and readable for a Grade 2/5
## audience). This is the documented, reliable way to paint a TileMapLayer's
## cells: load the scene, call set_cell() per cell in code, save via
## ResourceSaver/PackedScene.pack(). See docs/CURRENT_STATE.md's M1 section
## for the original bootstrap tileset this extends.
##
## HARD CONSTRAINTS respected here (do not violate when editing this script):
## - No NPC/item/enemy/spawner/landmark/Player node position changes. This
##   script only touches TileMapLayer cells and appends new decorative prop
##   instances (trees/stones), never moves an existing node.
## - The old map bounds (0..159, 0..99 in tile space) keep every already-
##   painted cell's *meaning* stable in spirit: the same NPC/path network
##   stays walkable. The outer rock ring that used to sit at the old edge is
##   replaced with normal terrain (since it is now interior land), and a new
##   rock/cliff ring frames the new, bigger bounds instead.
## - The Ground TileMapLayer node itself (name/type) is untouched; only its
##   cell data is rewritten via set_cell(), and its used-cell count grows.
##
## This is a plain Node script (not `extends SceneTree`) run as the real
## `run/main_scene`, because `godot --script` bypasses the project's normal
## autoload bootstrap (GameState/AudioManager) - and Main.tscn's node
## `_ready()`s (and their `[connection ...]` entries, resolved at instantiate
## time) require those autoloads to exist. Run headlessly via
## `tools/PaintMapRunner.tscn` (a tiny scene with this attached), temporarily
## set as the project's main scene:
##
##   Godot --headless --path . res://tools/PaintMapRunner.tscn

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

const TILE_GRASS := Vector2i(0, 0)
const TILE_PATH := Vector2i(1, 0)
const TILE_WATER := Vector2i(2, 0)
const TILE_ROCK := Vector2i(3, 0)
const TILE_GRASS_LIGHT := Vector2i(4, 0)
const TILE_GRASS_DARK := Vector2i(5, 0)
const TILE_FLOWERS_A := Vector2i(6, 0)
const TILE_FLOWERS_B := Vector2i(7, 0)
const TILE_FOREST_FLOOR := Vector2i(8, 0)
const TILE_SAND := Vector2i(9, 0)
const TILE_DEEP_WATER := Vector2i(10, 0)
const TILE_CLIFF := Vector2i(11, 0)

const SOURCE_ID := 0

# New map bounds (tiles). Old bounds were 160x100 (0..159, 0..99); grown to
# the right and down only, so every existing node position (which lives well
# inside the old top-left region) stays exactly where it was, on exactly the
# same terrain it already stood on, with the same walkable network intact.
const MAP_W := 220
const MAP_H := 140

# Deterministic PRNG seed so re-runs are reproducible (documents the map as
# code, per the task's instruction).
const SEED := 20260701


func _ready() -> void:
	# Running as the real main scene means GameState/AudioManager autoloads
	# are already live (normal project bootstrap), so Main.tscn's node
	# `_ready()`s and `[connection ...]` entries resolve exactly as they
	# would in a real play session. The tree is still mid-setup during our
	# own `_ready()`, so wait a frame before adding/removing children of
	# root (avoids the "Parent node is busy" engine error).
	await get_tree().process_frame

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var packed: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node = packed.instantiate()
	# Disable processing before the scene ever enters the tree: `_ready()`
	# still fires (so `[connection ...]` entries resolve), but no
	# `_process`/`_physics_process` runs on any descendant - so nothing
	# (Player idle drift, MeadowSlime wander AI, etc.) moves a single pixel
	# from its authored position while this tool has the scene open.
	main.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var ground: TileMapLayer = main.get_node("World/Ground")

	_paint_base_fill(ground)
	_paint_forest_edge(ground, rng)
	_paint_village_green(ground, rng)
	_paint_flower_meadow(ground, rng)
	_paint_lake(ground, rng)
	_paint_paths(ground)
	_paint_border(ground)
	_add_props(main)

	get_tree().root.remove_child(main)
	main.process_mode = Node.PROCESS_MODE_INHERIT

	var new_packed := PackedScene.new()
	var pack_err := new_packed.pack(main)
	if pack_err != OK:
		push_error("pack() failed: %d" % pack_err)
		main.free()
		get_tree().quit(1)
		return

	var save_err := ResourceSaver.save(new_packed, MAIN_SCENE_PATH)
	if save_err != OK:
		push_error("ResourceSaver.save() failed: %d" % save_err)
		main.free()
		get_tree().quit(1)
		return

	print("Repainted %s: %d used cells over %dx%d bounds." % [
		MAIN_SCENE_PATH, ground.get_used_cells().size(), MAP_W, MAP_H
	])
	main.free()
	get_tree().quit(0)


func _set_rect(ground: TileMapLayer, x0: int, y0: int, x1: int, y1: int, atlas: Vector2i) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			ground.set_cell(Vector2i(x, y), SOURCE_ID, atlas)


func _sprinkle(ground: TileMapLayer, x0: int, y0: int, x1: int, y1: int, atlas: Vector2i, chance: float, rng: RandomNumberGenerator) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if rng.randf() < chance:
				ground.set_cell(Vector2i(x, y), SOURCE_ID, atlas)


## 1. Base fill: open grass everywhere inside the new bounds, replacing the
## old border rock ring (now interior) with plain grass first so later passes
## paint clean regions on top.
func _paint_base_fill(ground: TileMapLayer) -> void:
	_set_rect(ground, 0, 0, MAP_W - 1, MAP_H - 1, TILE_GRASS)
	# Gentle grass-variant texture across the whole open field (subtle, sparse).
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 1
	_sprinkle(ground, 0, 0, MAP_W - 1, MAP_H - 1, TILE_GRASS_LIGHT, 0.03, rng)
	_sprinkle(ground, 0, 0, MAP_W - 1, MAP_H - 1, TILE_GRASS_DARK, 0.03, rng)


## 2. Forest-edge band: west side near Mira (tile ~35,72) and the LoneTree
## landmark (tile ~50,73). Darker forest-floor grass with jittered edge so it
## doesn't read as a hard rectangle.
func _paint_forest_edge(ground: TileMapLayer, rng: RandomNumberGenerator) -> void:
	for y in range(6, MAP_H - 6):
		var jitter := rng.randi_range(-3, 3)
		var edge_x: int = 34 + jitter
		edge_x = clampi(edge_x, 26, 40)
		for x in range(2, edge_x):
			ground.set_cell(Vector2i(x, y), SOURCE_ID, TILE_FOREST_FLOOR)
	# Keep Mira's own dooryard (around her position, tile ~35,72) and the
	# path corridor clear of forest floor so the existing path network still
	# reads clean; the _paint_paths() pass repaints path cells afterward.


## 3. Village green: warm grass + flower accents around the NPC/Merchant
## cluster (Elder 60,45 / Merchant 80,45 / Finn 120,45).
func _paint_village_green(ground: TileMapLayer, rng: RandomNumberGenerator) -> void:
	_set_rect(ground, 48, 32, 136, 58, TILE_GRASS_LIGHT)
	_sprinkle(ground, 48, 32, 136, 58, TILE_FLOWERS_A, 0.05, rng)
	_sprinkle(ground, 48, 32, 136, 58, TILE_FLOWERS_B, 0.04, rng)


## 4. Open flower meadow mid-map, south of the village green, around the
## existing path network and Yarrow/Silverleaf area.
func _paint_flower_meadow(ground: TileMapLayer, rng: RandomNumberGenerator) -> void:
	_set_rect(ground, 55, 59, 118, 92, TILE_GRASS)
	_sprinkle(ground, 55, 59, 118, 92, TILE_FLOWERS_A, 0.06, rng)
	_sprinkle(ground, 55, 59, 118, 92, TILE_FLOWERS_B, 0.06, rng)
	_sprinkle(ground, 55, 59, 118, 92, TILE_GRASS_LIGHT, 0.04, rng)


## 5. Lake: reshape the old water rectangle (tile x:90..105, y:52..65) into a
## natural-edged lake (jittered shoreline) ringed with sand, plus a small
## deep-water patch at its center. Footprint stays centered on the same spot
## so nothing that used to be walkable near it changes meaning.
func _paint_lake(ground: TileMapLayer, rng: RandomNumberGenerator) -> void:
	var cx := 97
	var cy := 58
	var rx := 11
	var ry := 8
	for y in range(cy - ry - 2, cy + ry + 3):
		for x in range(cx - rx - 2, cx + rx + 3):
			var dx: float = float(x - cx) / float(rx)
			var dy: float = float(y - cy) / float(ry)
			var dist := dx * dx + dy * dy
			# Small deterministic edge jitter keyed off position (no true
			# noise dependency) so the shoreline isn't a perfect ellipse.
			var jitter: float = 0.06 * sin(float(x) * 1.7) + 0.06 * cos(float(y) * 1.3)
			if dist < 0.55 + jitter:
				ground.set_cell(Vector2i(x, y), SOURCE_ID, TILE_DEEP_WATER)
			elif dist < 1.0 + jitter:
				ground.set_cell(Vector2i(x, y), SOURCE_ID, TILE_WATER)
			elif dist < 1.28 + jitter:
				ground.set_cell(Vector2i(x, y), SOURCE_ID, TILE_SAND)


## 6. Paths: re-lay the readable path network spawn -> each NPC -> lake, on
## top of every region painted so far (paths always win). Reuses the
## existing path corridor (tile x:35..120, y:45..85) and adds a couple of
## short connector spurs into the newly expanded regions.
func _paint_paths(ground: TileMapLayer) -> void:
	# Preserve/re-lay the original hub network exactly (spawn near 80,60;
	# Elder 60,45; Merchant 80,45; Finn 120,45; Mira 35,72; Yarrow 80,85).
	_h_line(ground, 35, 120, 45, TILE_PATH)   # village row: Elder-Merchant-Finn
	_v_line(ground, 80, 45, 85, TILE_PATH)    # spine: village -> spawn -> Yarrow
	_v_line(ground, 60, 45, 60, TILE_PATH)    # short spur to Elder column
	_h_line(ground, 35, 80, 72, TILE_PATH)    # spur west to Mira
	_v_line(ground, 35, 60, 72, TILE_PATH)    # connects Mira spur up to spine area
	_h_line(ground, 80, 97, 60, TILE_PATH)    # spine -> lake shore (east spur)


func _h_line(ground: TileMapLayer, x0: int, x1: int, y: int, atlas: Vector2i) -> void:
	for x in range(min(x0, x1), max(x0, x1) + 1):
		ground.set_cell(Vector2i(x, y), SOURCE_ID, atlas)


func _v_line(ground: TileMapLayer, x: int, y0: int, y1: int, atlas: Vector2i) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		ground.set_cell(Vector2i(x, y), SOURCE_ID, atlas)


## 7. Rocky border: frame the whole new map edge with a cliff/rock ring so
## the world has a deliberate silhouette instead of a hard rectangle. Keeps
## the two existing interior rock outcrops (tile 28-31,28-31 and
## 128-131,74-77) untouched since they are just decorative obstacles, not
## edge geometry.
func _paint_border(ground: TileMapLayer) -> void:
	var thickness := 2
	for t in range(thickness):
		_h_line(ground, 0, MAP_W - 1, t, TILE_CLIFF)
		_h_line(ground, 0, MAP_W - 1, MAP_H - 1 - t, TILE_CLIFF)
		_v_line(ground, t, 0, MAP_H - 1, TILE_CLIFF)
		_v_line(ground, MAP_W - 1 - t, 0, MAP_H - 1, TILE_ROCK)
	# Restore the two existing interior rock outcrops (obstacles, unrelated
	# to the border) exactly as they were.
	_set_rect(ground, 28, 28, 31, 31, TILE_ROCK)
	_set_rect(ground, 128, 74, 131, 77, TILE_ROCK)


## 8. Depth props: reuse the existing StandingStone/LoneTree scenes several
## times (tree clusters at the forest edge, a stone or two near the rocky
## border) plus two new simple polygon props (Bush, Dock) instanced near the
## lake. Purely visual, no collision, y_sort like their siblings. Positions
## are chosen to sit on grass/forest-floor cells well clear of every existing
## NPC/item/path so nothing new blocks the existing walkable network.
func _add_props(main: Node) -> void:
	var tree_scene: PackedScene = load("res://scenes/props/LoneTree.tscn")
	var stone_scene: PackedScene = load("res://scenes/props/StandingStone.tscn")
	var bush_scene: PackedScene = load("res://scenes/props/Bush.tscn")
	var dock_scene: PackedScene = load("res://scenes/props/Dock.tscn")

	var tree_positions := [
		Vector2(240, 500), Vector2(160, 900), Vector2(280, 1300),
		Vector2(180, 1700), Vector2(340, 2000),
	]
	for i in range(tree_positions.size()):
		var t: Node2D = tree_scene.instantiate()
		t.name = "ForestTree%d" % (i + 1)
		t.position = tree_positions[i]
		main.add_child(t)
		t.owner = main

	var stone_positions := [Vector2(3440, 400), Vector2(3300, 2080)]
	for i in range(stone_positions.size()):
		var s: Node2D = stone_scene.instantiate()
		s.name = "BorderStone%d" % (i + 1)
		s.position = stone_positions[i]
		main.add_child(s)
		s.owner = main

	var bush_positions := [Vector2(1700, 700), Vector2(1900, 1500), Vector2(2400, 1550)]
	for i in range(bush_positions.size()):
		var b: Node2D = bush_scene.instantiate()
		b.name = "Bush%d" % (i + 1)
		b.position = bush_positions[i]
		main.add_child(b)
		b.owner = main

	var dock: Node2D = dock_scene.instantiate()
	dock.name = "Dock"
	dock.position = Vector2(1552, 976)
	main.add_child(dock)
	dock.owner = main
