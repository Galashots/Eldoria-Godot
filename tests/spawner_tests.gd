extends RefCounted

## Unit tests for the pure spawn-scheduling logic behind the gentle repeatable coin faucet
## (Spawner.gd). Kept in its own file (registered in tests/test_runner.gd), same pattern as
## tests/hit_flash_tests.gd, rather than appended to game_state_tests.gd.
##
## Each test_* returns {"ok": bool, "failures": Array[String]} like the other suites.

const Spawner := preload("res://scripts/enemies/Spawner.gd")

func test_schedules_respawn_when_under_cap() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, Spawner.should_schedule_respawn(2, 0, 3),
        "expected a respawn to be scheduled when live_count + pending < max_count")
    return {"ok": failures.is_empty(), "failures": failures}

func test_does_not_exceed_cap_when_a_respawn_is_already_pending() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, not Spawner.should_schedule_respawn(2, 1, 3),
        "expected no new respawn scheduled once live_count + pending already reaches max_count")
    return {"ok": failures.is_empty(), "failures": failures}

func test_does_not_exceed_cap_when_full() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, not Spawner.should_schedule_respawn(3, 0, 3),
        "expected no respawn scheduled when the live count already equals the cap")
    return {"ok": failures.is_empty(), "failures": failures}

func test_never_schedules_beyond_original_count_even_with_multiple_pending() -> Dictionary:
    var failures: Array[String] = []
    _check(failures, not Spawner.should_schedule_respawn(0, 3, 3),
        "expected no respawn scheduled when pending alone already reaches the cap")
    return {"ok": failures.is_empty(), "failures": failures}

func test_count_due_is_zero_before_the_delay_elapses() -> Dictionary:
    var failures: Array[String] = []
    var pending: Array = [25.0, 10.0]
    _check(failures, Spawner.count_due(pending, 5.0) == 0,
        "expected no respawns due before their delay has elapsed")
    return {"ok": failures.is_empty(), "failures": failures}

func test_count_due_counts_only_entries_whose_delay_has_elapsed() -> Dictionary:
    var failures: Array[String] = []
    var pending: Array = [25.0, 10.0, 3.0]
    _check(failures, Spawner.count_due(pending, 12.0) == 2,
        "expected exactly the entries with remaining <= elapsed to be counted as due")
    return {"ok": failures.is_empty(), "failures": failures}

func test_count_due_treats_exact_delay_match_as_due() -> Dictionary:
    var failures: Array[String] = []
    var pending: Array = [25.0]
    _check(failures, Spawner.count_due(pending, 25.0) == 1,
        "expected remaining == elapsed (exactly the configured delay) to count as due")
    return {"ok": failures.is_empty(), "failures": failures}

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
