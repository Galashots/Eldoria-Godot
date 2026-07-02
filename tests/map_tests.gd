extends RefCounted

## Regression tests for the "epic map pass" (docs/design/NORTH_STAR.md mandate): confirms
## the repainted/extended World/Ground TileMapLayer grew as intended, that no existing
## NPC/item/enemy/Player node moved from its original authored position (the hard
## quest-breakage-protection constraint), and that the Player's Camera2D limits match the
## new map bounds. Kept in its own file (registered in tests/test_runner.gd), same pattern
## as tests/hit_flash_tests.gd/tests/spawner_tests.gd, rather than appended to
## game_state_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

# Hardcoded original positions (observed before this pass repainted the map) - if any of
# these ever legitimately needs to change, update this table deliberately, not by accident.
const EXPECTED_POSITIONS := {
    "Player": Vector2(1288, 968),
    "Elder": Vector2(968, 728),
    "Mira": Vector2(568, 1160),
    "Finn": Vector2(1928, 728),
    "Yarrow": Vector2(1288, 1368),
    "Merchant": Vector2(1288, 728),
    "Collectible": Vector2(1048, 808),
    "GlowingHerb": Vector2(728, 1096),
    "ShimmeringOre": Vector2(1800, 808),
    "Silverleaf": Vector2(1128, 1288),
}

const EXPECTED_ENEMY_POSITIONS := {
    "MeadowSlime1": Vector2(1608, 1208),
    "MeadowSlime2": Vector2(728, 488),
    "MeadowSlime3": Vector2(2088, 968),
}

const OLD_USED_CELL_THRESHOLD := 16000
const EXPECTED_CAMERA_LIMIT_RIGHT := 3520
const EXPECTED_CAMERA_LIMIT_BOTTOM := 2240


func test_ground_tilemaplayer_exists_and_grew_past_the_old_zone() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var ground := main.get_node_or_null("World/Ground")
    _check(failures, ground != null, "expected World/Ground to exist")
    if ground != null:
        _check(failures, ground is TileMapLayer, "expected World/Ground to be a TileMapLayer")
        var used_count: int = (ground as TileMapLayer).get_used_cells().size()
        _check(failures, used_count > OLD_USED_CELL_THRESHOLD,
            "expected used-cell count (%d) to have grown past the old zone's %d" % [used_count, OLD_USED_CELL_THRESHOLD])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_every_npc_and_item_stayed_at_its_original_position() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    for node_name in EXPECTED_POSITIONS.keys():
        var node := main.get_node_or_null(NodePath(node_name)) as Node2D
        _check(failures, node != null, "expected node '%s' to still exist" % node_name)
        if node != null:
            var expected: Vector2 = EXPECTED_POSITIONS[node_name]
            _check(failures, node.position.is_equal_approx(expected),
                "expected %s at %s, found %s" % [node_name, expected, node.position])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_every_enemy_stayed_at_its_original_spawn_position() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    for node_name in EXPECTED_ENEMY_POSITIONS.keys():
        var node := main.get_node_or_null(NodePath("Enemies/" + node_name)) as Node2D
        _check(failures, node != null, "expected enemy node '%s' to still exist" % node_name)
        if node != null:
            var expected: Vector2 = EXPECTED_ENEMY_POSITIONS[node_name]
            _check(failures, node.position.is_equal_approx(expected),
                "expected %s at %s, found %s" % [node_name, expected, node.position])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_camera_limits_match_the_new_map_bounds() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var camera := main.get_node_or_null("Player/Camera2D") as Camera2D
    _check(failures, camera != null, "expected Player/Camera2D to exist")
    if camera != null:
        _check(failures, camera.limit_left == 0, "expected limit_left == 0")
        _check(failures, camera.limit_top == 0, "expected limit_top == 0")
        _check(failures, camera.limit_right == EXPECTED_CAMERA_LIMIT_RIGHT,
            "expected limit_right == %d, found %d" % [EXPECTED_CAMERA_LIMIT_RIGHT, camera.limit_right])
        _check(failures, camera.limit_bottom == EXPECTED_CAMERA_LIMIT_BOTTOM,
            "expected limit_bottom == %d, found %d" % [EXPECTED_CAMERA_LIMIT_BOTTOM, camera.limit_bottom])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_landmark_props_still_exist_at_their_original_positions() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var stone := main.get_node_or_null("StandingStone") as Node2D
    _check(failures, stone != null, "expected StandingStone to still exist")
    if stone != null:
        _check(failures, stone.position.is_equal_approx(Vector2(1120, 828)),
            "expected StandingStone at (1120, 828), found %s" % stone.position)

    var tree := main.get_node_or_null("LoneTree") as Node2D
    _check(failures, tree != null, "expected LoneTree to still exist")
    if tree != null:
        _check(failures, tree.position.is_equal_approx(Vector2(800, 1180)),
            "expected LoneTree at (800, 1180), found %s" % tree.position)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
