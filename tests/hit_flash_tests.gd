extends RefCounted

## Unit tests for the pure hit-reaction easing that drives the combat hit-flash (both the
## enemy's HealthComponent pop/tint and the player's hurt pop/tint). Kept in its own file
## (registered in tests/test_runner.gd) rather than appended to game_state_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the GameState suite.

func test_intensity_is_full_at_the_instant_of_the_hit() -> Dictionary:
    var failures: Array[String] = []
    var duration := HealthComponent.FLASH_DURATION_SEC
    _check(failures, is_equal_approx(HealthComponent.hit_reaction_intensity(duration, duration), 1.0),
        "expected intensity 1.0 when remaining == duration (the hit instant)")
    return {"ok": failures.is_empty(), "failures": failures}

func test_intensity_is_zero_when_the_flash_has_elapsed() -> Dictionary:
    var failures: Array[String] = []
    var duration := HealthComponent.FLASH_DURATION_SEC
    _check(failures, HealthComponent.hit_reaction_intensity(0.0, duration) == 0.0,
        "expected intensity 0.0 when the flash has fully elapsed")
    return {"ok": failures.is_empty(), "failures": failures}

func test_intensity_decays_linearly_across_the_flash() -> Dictionary:
    var failures: Array[String] = []
    var duration := 0.08
    _check(failures, is_equal_approx(HealthComponent.hit_reaction_intensity(0.04, duration), 0.5),
        "expected intensity 0.5 at the flash midpoint")
    _check(failures, is_equal_approx(HealthComponent.hit_reaction_intensity(0.02, duration), 0.25),
        "expected intensity 0.25 at a quarter remaining")
    return {"ok": failures.is_empty(), "failures": failures}

func test_intensity_is_clamped_to_zero_one() -> Dictionary:
    var failures: Array[String] = []
    var duration := 0.08
    _check(failures, HealthComponent.hit_reaction_intensity(0.5, duration) == 1.0,
        "expected remaining > duration to clamp to 1.0")
    _check(failures, HealthComponent.hit_reaction_intensity(-1.0, duration) == 0.0,
        "expected negative remaining to clamp to 0.0")
    return {"ok": failures.is_empty(), "failures": failures}

func test_zero_duration_is_safe() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, HealthComponent.hit_reaction_intensity(1.0, 0.0) == 0.0,
        "expected a zero/negative duration to return 0.0 rather than divide by zero")
    return {"ok": failures.is_empty(), "failures": failures}

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
