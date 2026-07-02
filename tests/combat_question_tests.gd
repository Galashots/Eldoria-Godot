extends RefCounted

## Combat numeracy pool tests. Isolated file (registered in tests/test_runner.gd), covering
## the "Expand combat numeracy pool + gentle ramp" expansion-loop slice: pool size per profile
## and the pure, static no-immediate-repeat draw (CombatQuestion.pick_next_index()). Each
## test_* returns {"ok": bool, "failures": Array[String]}, mirroring every other isolated
## suite's shape.

const CombatQuestion := preload("res://scripts/ui/CombatQuestion.gd")

func test_grade_2_pool_has_at_least_twelve_items() -> Dictionary:
    var failures: Array[String] = []
    var pool: Array = CombatQuestion.QUESTION_POOL.get("grade_2_mage", [])

    _check(failures, pool.size() >= 12, "expected grade_2_mage pool size >= 12, got %d" % pool.size())

    return {"ok": failures.is_empty(), "failures": failures}

func test_grade_5_pool_has_at_least_twelve_items() -> Dictionary:
    var failures: Array[String] = []
    var pool: Array = CombatQuestion.QUESTION_POOL.get("grade_5_adventurer", [])

    _check(failures, pool.size() >= 12, "expected grade_5_adventurer pool size >= 12, got %d" % pool.size())

    return {"ok": failures.is_empty(), "failures": failures}

func test_every_pool_item_has_two_choices_and_a_correct_answer() -> Dictionary:
    var failures: Array[String] = []

    for profile in CombatQuestion.QUESTION_POOL.keys():
        var pool: Array = CombatQuestion.QUESTION_POOL[profile]
        for i in range(pool.size()):
            var item: Dictionary = pool[i]
            var choices: Array = item.get("choices", [])
            _check(failures, choices.size() == 2, "%s item %d expected 2 choices, got %d" % [profile, i, choices.size()])
            _check(failures, choices.has(item.get("correct", "")), "%s item %d correct answer not among choices" % [profile, i])

    return {"ok": failures.is_empty(), "failures": failures}

func test_pick_next_index_never_repeats_last_index_for_pool_size_above_one() -> Dictionary:
    var failures: Array[String] = []
    var pool_size := 12

    var last_index := 0
    # Sweep a spread of rolls across many "last picks" to prove the property holds broadly,
    # not just for one lucky roll value.
    for start in range(pool_size):
        last_index = start
        var rolls := [0.0, 0.1, 0.25, 0.49, 0.5, 0.75, 0.99]
        for roll in rolls:
            var next_index := CombatQuestion.pick_next_index(pool_size, last_index, roll)
            _check(failures, next_index != last_index, "pick_next_index repeated last_index %d (roll=%s)" % [last_index, roll])
            _check(failures, next_index >= 0 and next_index < pool_size, "pick_next_index returned out-of-range index %d" % next_index)

    return {"ok": failures.is_empty(), "failures": failures}

func test_pick_next_index_single_item_pool_returns_zero_without_looping() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, CombatQuestion.pick_next_index(1, -1, 0.0) == 0, "expected index 0 for a fresh single-item pool")
    _check(failures, CombatQuestion.pick_next_index(1, 0, 0.5) == 0, "expected index 0 even when last_index is the only slot")
    _check(failures, CombatQuestion.pick_next_index(0, -1, 0.5) == 0, "expected index 0 for an empty pool (degenerate edge case)")

    return {"ok": failures.is_empty(), "failures": failures}

func test_pick_next_index_handles_no_prior_pick() -> Dictionary:
    var failures: Array[String] = []
    var pool_size := 12

    var index := CombatQuestion.pick_next_index(pool_size, -1, 0.999)
    _check(failures, index >= 0 and index < pool_size, "expected a valid index with no prior pick, got %d" % index)

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
