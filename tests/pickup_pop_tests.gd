extends RefCounted

## Unit tests for the pure pop-scale easing that drives the "gentle pickup pop" (coins,
## collectibles, sparkle-spots). Kept in its own file (registered in tests/test_runner.gd),
## mirroring tests/hit_flash_tests.gd's shape exactly.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

func test_scale_starts_at_rest_at_t_zero() -> Dictionary:
    var failures: Array[String] = []
    var duration := PickupPop.POP_DURATION_SEC
    _check(failures, is_equal_approx(PickupPop.pop_scale_multiplier(0.0, duration), 1.0),
        "expected multiplier 1.0 (no change) at t=0")
    return {"ok": failures.is_empty(), "failures": failures}

func test_scale_returns_to_rest_at_duration() -> Dictionary:
    var failures: Array[String] = []
    var duration := PickupPop.POP_DURATION_SEC
    _check(failures, is_equal_approx(PickupPop.pop_scale_multiplier(duration, duration), 1.0),
        "expected multiplier 1.0 (settled) once the pop has fully elapsed")
    return {"ok": failures.is_empty(), "failures": failures}

func test_scale_grows_above_rest_partway_through() -> Dictionary:
    var failures: Array[String] = []
    var duration := PickupPop.POP_DURATION_SEC
    var mid := PickupPop.pop_scale_multiplier(duration * 0.2, duration)
    _check(failures, mid > 1.0,
        "expected the scale to grow above 1.0 during the quick grow phase, got %f" % mid)
    return {"ok": failures.is_empty(), "failures": failures}

func test_scale_never_exceeds_the_configured_peak() -> Dictionary:
    var failures: Array[String] = []
    var duration := PickupPop.POP_DURATION_SEC
    var peak := PickupPop.POP_PEAK_SCALE
    var max_seen := 0.0
    var steps := 50
    for i in range(steps + 1):
        var t := duration * float(i) / float(steps)
        max_seen = maxf(max_seen, PickupPop.pop_scale_multiplier(t, duration))
    _check(failures, max_seen <= peak + 0.001,
        "expected max sampled scale (%f) to never exceed the configured peak (%f)" % [max_seen, peak])
    _check(failures, PickupPop.POP_PEAK_SCALE <= 1.3 + 0.001,
        "expected the configured peak to stay within the gentle 1.3x kid-audience cap")
    return {"ok": failures.is_empty(), "failures": failures}

func test_scale_is_clamped_past_the_duration() -> Dictionary:
    var failures: Array[String] = []
    var duration := PickupPop.POP_DURATION_SEC
    _check(failures, is_equal_approx(PickupPop.pop_scale_multiplier(duration * 5.0, duration), 1.0),
        "expected t far past duration to clamp to the rest scale")
    return {"ok": failures.is_empty(), "failures": failures}

func test_zero_duration_is_safe() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, PickupPop.pop_scale_multiplier(0.1, 0.0) == 1.0,
        "expected a zero/negative duration to return 1.0 rather than divide by zero")
    return {"ok": failures.is_empty(), "failures": failures}

func test_coin_pickup_awards_before_any_pop_delay() -> Dictionary:
    var failures: Array[String] = []
    var coin_scene: PackedScene = load("res://scenes/items/CoinPickup.tscn")
    var coin := coin_scene.instantiate()
    coin.value = 1
    var starting_coins := GameState.coins
    var toucher := CharacterBody2D.new()
    coin._on_body_entered(toucher)
    _check(failures, GameState.coins == starting_coins + 1,
        "expected the coin award to apply immediately, before the pop tween settles")
    coin.free()
    toucher.free()
    return {"ok": failures.is_empty(), "failures": failures}

func test_collectible_awards_before_any_pop_delay() -> Dictionary:
    var failures: Array[String] = []
    var collectible_scene: PackedScene = load("res://scenes/items/Collectible.tscn")
    var collectible := collectible_scene.instantiate()
    collectible.item_id = "pickup_pop_test_item"
    var toucher := CharacterBody2D.new()
    collectible._on_body_entered(toucher)
    _check(failures, GameState.has_item("pickup_pop_test_item"),
        "expected the item award to apply immediately, before the pop tween settles")
    collectible.free()
    toucher.free()
    return {"ok": failures.is_empty(), "failures": failures}

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
