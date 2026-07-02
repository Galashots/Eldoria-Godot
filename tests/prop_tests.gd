extends RefCounted

## Regression tests for the "Forest-edge signature: pine-cluster props" slice
## (docs/design/EXPANSION_BACKLOG.md). Confirms the new PineTree instances exist in
## Main.tscn, and reuses AudioManager.region_for_position() (the same region-lookup helper
## the ambience/particle passes already established) to assert each pine actually sits
## inside the forest_edge region rectangle. Kept in its own file (registered in
## tests/test_runner.gd), same pattern as tests/map_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

const EXPECTED_PINE_NAMES := [
    "PineCluster1", "PineCluster2", "PineCluster3", "PineCluster4", "PineCluster5",
]


func test_pine_cluster_nodes_exist_in_main_scene() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    for node_name in EXPECTED_PINE_NAMES:
        var node := main.get_node_or_null(NodePath(node_name)) as Node2D
        _check(failures, node != null, "expected pine node '%s' to exist" % node_name)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_every_pine_sits_in_the_forest_edge_region() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    for node_name in EXPECTED_PINE_NAMES:
        var node := main.get_node_or_null(NodePath(node_name)) as Node2D
        if node == null:
            failures.append("expected pine node '%s' to exist" % node_name)
            continue
        var region := AudioManager.region_for_position(
            node.position, AudioManager.REGION_RECTS, AudioManager.DEFAULT_REGION)
        _check(failures, region == "forest_edge",
            "expected %s at %s to be in the forest_edge region, found '%s'"
                % [node_name, node.position, region])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_pine_tree_scene_has_no_collision_and_is_y_sorted() -> Dictionary:
    var failures: Array[String] = []
    var pine: Node2D = load("res://scenes/props/PineTree.tscn").instantiate()

    _check(failures, pine.y_sort_enabled, "expected PineTree to have y_sort_enabled")
    _check(failures, pine.get_script() == null, "expected PineTree to have no script")

    var has_collision := false
    for child in pine.get_children():
        if child is CollisionObject2D or child is CollisionShape2D or child is CollisionPolygon2D:
            has_collision = true
    _check(failures, not has_collision, "expected PineTree to have no collision nodes")

    pine.free()
    return {"ok": failures.is_empty(), "failures": failures}


static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
