extends RefCounted

## Unit tests for AudioManager's pure logic (the "did coins increase" helper that decides
## whether to play the coin chime). Kept in its own file (registered in
## tests/test_runner.gd) per the sound-pass slice, rather than appended to
## game_state_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

func test_coins_increased_is_true_when_coins_went_up() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, AudioManager.coins_increased(0, 1) == true,
        "expected coins_increased(0, 1) to be true")
    _check(failures, AudioManager.coins_increased(5, 8) == true,
        "expected coins_increased(5, 8) to be true")
    return {"ok": failures.is_empty(), "failures": failures}

func test_coins_increased_is_false_when_coins_stayed_the_same_or_dropped() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, AudioManager.coins_increased(4, 4) == false,
        "expected coins_increased(4, 4) to be false (unchanged)")
    _check(failures, AudioManager.coins_increased(10, 3) == false,
        "expected coins_increased(10, 3) to be false (a spend/decrease)")
    return {"ok": failures.is_empty(), "failures": failures}

func test_play_sfx_with_unknown_name_is_a_silent_no_op() -> Dictionary:
    var failures: Array[String] = []
    # Should not push an error or crash - just a push_warning and an early return.
    AudioManager.play_sfx("not_a_real_sound")
    _check(failures, true, "play_sfx with an unknown name should not throw")
    return {"ok": failures.is_empty(), "failures": failures}

## --- Region ambience pass: region_for_position() and crossfade_volume_db() coverage. ---

func _sample_region_rects() -> Dictionary:
    return {
        "lake": Rect2(1344.0, 768.0, 416.0, 320.0),
        "forest_edge": Rect2(32.0, 96.0, 608.0, 2064.0),
        "village_green": Rect2(768.0, 512.0, 1424.0, 432.0),
        "flower_meadow": Rect2(880.0, 944.0, 1024.0, 544.0),
        "rocky_border": Rect2(0.0, 0.0, 3520.0, 2240.0),
    }

func test_region_for_position_matches_inside_each_rect() -> Dictionary:
    var failures: Array[String] = []
    var rects := _sample_region_rects()
    _check(failures, AudioManager.region_for_position(Vector2(1500, 900), rects, "village_green") == "lake",
        "expected a point inside the lake rect to resolve to 'lake'")
    _check(failures, AudioManager.region_for_position(Vector2(200, 1000), rects, "village_green") == "forest_edge",
        "expected a point inside the forest-edge rect to resolve to 'forest_edge'")
    _check(failures, AudioManager.region_for_position(Vector2(1300, 950), rects, "village_green") == "flower_meadow",
        "expected a point inside the flower-meadow rect (outside lake/forest) to resolve to 'flower_meadow'")
    return {"ok": failures.is_empty(), "failures": failures}

func test_region_for_position_prefers_first_match_on_overlap() -> Dictionary:
    var failures: Array[String] = []
    var rects := _sample_region_rects()
    # The lake rect sits inside the map-spanning rocky_border rect; since lake is listed
    # first, a lake-interior point must resolve to "lake", not "rocky_border".
    _check(failures, AudioManager.region_for_position(Vector2(1500, 900), rects, "village_green") == "lake",
        "expected the first matching rect (lake) to win over a later, larger overlapping rect")
    return {"ok": failures.is_empty(), "failures": failures}

func test_region_for_position_outside_all_rects_returns_default() -> Dictionary:
    var failures: Array[String] = []
    var empty_rects := {}
    _check(failures, AudioManager.region_for_position(Vector2(-500, -500), empty_rects, "village_green") == "village_green",
        "expected a position with no matching rects to fall back to the default region")
    return {"ok": failures.is_empty(), "failures": failures}

func test_region_for_position_boundary_edges() -> Dictionary:
    var failures: Array[String] = []
    var rects := {"zone": Rect2(0.0, 0.0, 100.0, 100.0)}
    _check(failures, AudioManager.region_for_position(Vector2(0, 0), rects, "outside") == "zone",
        "expected the rect's top-left corner (inclusive) to match")
    _check(failures, AudioManager.region_for_position(Vector2(99, 99), rects, "outside") == "zone",
        "expected a point just inside the rect's far edge to match")
    _check(failures, AudioManager.region_for_position(Vector2(100, 100), rects, "outside") == "outside",
        "expected the rect's far edge (exclusive, Rect2.has_point convention) to not match")
    _check(failures, AudioManager.region_for_position(Vector2(-1, 50), rects, "outside") == "outside",
        "expected a point just outside the rect's near edge to not match")
    return {"ok": failures.is_empty(), "failures": failures}

func test_crossfade_volume_db_endpoints() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(0.0, -18.0, true), -80.0),
        "expected an incoming track at t=0 to start silent (-80 dB)")
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(1.0, -18.0, true), -18.0),
        "expected an incoming track at t=1 to reach the target ambient volume")
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(0.0, -18.0, false), -18.0),
        "expected an outgoing track at t=0 to still be at full ambient volume")
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(1.0, -18.0, false), -80.0),
        "expected an outgoing track at t=1 to have faded to silent")
    return {"ok": failures.is_empty(), "failures": failures}

func test_crossfade_volume_db_midpoint_and_clamping() -> Dictionary:
    var failures: Array[String] = []
    var mid := AudioManager.crossfade_volume_db(0.5, -18.0, true)
    _check(failures, mid > -80.0 and mid < -18.0,
        "expected the incoming track's midpoint volume to sit strictly between silent and target")
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(-0.5, -18.0, true), -80.0),
        "expected t below 0 to clamp to the silent endpoint")
    _check(failures, is_equal_approx(AudioManager.crossfade_volume_db(1.5, -18.0, true), -18.0),
        "expected t above 1 to clamp to the target endpoint")
    return {"ok": failures.is_empty(), "failures": failures}

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
