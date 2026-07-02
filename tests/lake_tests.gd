extends RefCounted

## "Living lake" (expansion backlog): a small scene-assertion suite (mirroring
## tests/map_tests.gd's style) confirming the animated water-shimmer overlay exists, is
## positioned/sized over the lake's footprint (tools/paint_map.gd's _paint_lake: tile rect
## x:84..110, y:48..68, i.e. world px (1344, 768) size (416, 320)), sits under the
## Player/NPC/prop y-sort layer (y_sort_enabled == false so it stays in Ground's draw slot,
## never sorted above actors), and carries a low-alpha ShaderMaterial so it degrades safely
## if the shader ever fails to compile (a ColorRect always renders its own flat modulate
## color as a fallback). Registered in tests/test_runner.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

const EXPECTED_POSITION := Vector2(1344, 768)
const LAKE_SHORE_SPARKLE_POSITION := Vector2(1728, 864)


func test_lake_shimmer_exists_under_world_ground() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var shimmer := main.get_node_or_null("World/LakeShimmer")
    _check(failures, shimmer != null, "expected World/LakeShimmer to exist")
    if shimmer != null:
        _check(failures, shimmer is Node2D, "expected World/LakeShimmer to be a Node2D")

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_lake_shimmer_is_positioned_over_the_lake_footprint() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var shimmer := main.get_node_or_null("World/LakeShimmer") as Node2D
    _check(failures, shimmer != null, "expected World/LakeShimmer to exist")
    if shimmer != null:
        _check(failures, shimmer.position.is_equal_approx(EXPECTED_POSITION),
            "expected LakeShimmer at %s, found %s" % [EXPECTED_POSITION, shimmer.position])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_lake_shimmer_overlay_covers_the_lake_bounding_box() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var overlay := main.get_node_or_null("World/LakeShimmer/Overlay") as ColorRect
    _check(failures, overlay != null, "expected World/LakeShimmer/Overlay ColorRect to exist")
    if overlay != null:
        _check(failures, overlay.size.x >= 416.0 and overlay.size.y >= 320.0,
            "expected the shimmer overlay to cover at least the 416x320 lake bounding box, found %s" % overlay.size)
        _check(failures, overlay.material is ShaderMaterial,
            "expected the overlay to use a ShaderMaterial")
        _check(failures, overlay.color.a <= 0.05,
            "expected a near-invisible flat fallback color (a <= 0.05), found alpha %s" % overlay.color.a)

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_lake_shimmer_stays_under_the_actor_ysort_layer() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var shimmer := main.get_node_or_null("World/LakeShimmer") as Node2D
    _check(failures, shimmer != null, "expected World/LakeShimmer to exist")
    if shimmer != null:
        _check(failures, shimmer.y_sort_enabled == false,
            "expected LakeShimmer.y_sort_enabled == false, so it never draws above an actor via y-sort")

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


func test_lake_shore_sparkle_still_exists_and_is_not_moved() -> Dictionary:
    var failures: Array[String] = []
    var main: Node = load(MAIN_SCENE_PATH).instantiate()

    var sparkle := main.get_node_or_null("LakeShoreSparkle") as Node2D
    _check(failures, sparkle != null, "expected LakeShoreSparkle to still exist")
    if sparkle != null:
        _check(failures, sparkle.position.is_equal_approx(LAKE_SHORE_SPARKLE_POSITION),
            "expected LakeShoreSparkle at %s, found %s" % [LAKE_SHORE_SPARKLE_POSITION, sparkle.position])

    main.free()
    return {"ok": failures.is_empty(), "failures": failures}


static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
