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

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
