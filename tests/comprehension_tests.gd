extends RefCounted

## Elder's "what did you notice?" bonus-only reading-comprehension check. Isolated file
## (registered in tests/test_runner.gd) per the conductor directive: new tests avoid the
## game_state_tests.gd merge hotspot. Same conventions: each test_* runs against a freshly
## reset GameState singleton and returns {"ok": bool, "failures": Array[String]}. Named
## signal-probe methods, not lambdas - a lambda connected to a GameState signal does not
## reliably fire on this Godot 4.7 build (see the note at the top of tests/game_state_tests.gd).

const ComprehensionCheckScript := preload("res://scripts/ui/ComprehensionCheck.gd")

var _bonus_awarded_count: int = 0
var _last_bonus_entry_id: String = ""

func _on_comprehension_bonus_awarded_probe(entry_id: String) -> void:
    _bonus_awarded_count += 1
    _last_bonus_entry_id = entry_id

func test_find_eligible_entry_skips_answered_and_no_question_entries() -> Dictionary:
    var failures: Array[String] = []

    var unlocked := ["meadow_slime", "unknown_entry"]
    var answered := {}
    var found := ComprehensionCheckScript.find_eligible_entry(unlocked, answered, "grade_2_mage")
    _check(failures, found == "meadow_slime", "expected meadow_slime eligible, got %s" % found)

    answered = {"meadow_slime": true}
    found = ComprehensionCheckScript.find_eligible_entry(unlocked, answered, "grade_2_mage")
    _check(failures, found == "", "expected no eligible entry once meadow_slime is answered, got %s" % found)

    return {"ok": failures.is_empty(), "failures": failures}

func test_find_eligible_entry_returns_empty_for_unmet_entries() -> Dictionary:
    var failures: Array[String] = []

    var found := ComprehensionCheckScript.find_eligible_entry([], {}, "grade_2_mage")
    _check(failures, found == "", "expected no eligible entry with nothing unlocked, got %s" % found)

    return {"ok": failures.is_empty(), "failures": failures}

func test_is_answer_correct() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, ComprehensionCheckScript.is_answer_correct("A coin", "A coin"), "expected matching answers to be correct")
    _check(failures, not ComprehensionCheckScript.is_answer_correct("A sword", "A coin"), "expected mismatched answers to be incorrect")

    return {"ok": failures.is_empty(), "failures": failures}

func test_get_comprehension_question_has_both_profiles_for_seeded_entries() -> Dictionary:
    var failures: Array[String] = []

    var g2 := ContentDefinitions.get_comprehension_question("meadow_slime", "grade_2_mage")
    var g5 := ContentDefinitions.get_comprehension_question("meadow_slime", "grade_5_adventurer")
    _check(failures, not g2.is_empty(), "expected a grade_2_mage question for meadow_slime")
    _check(failures, not g5.is_empty(), "expected a grade_5_adventurer question for meadow_slime")
    _check(failures, g2.get("question", "") != g5.get("question", ""), "expected the two profiles to have different question text")

    var keepsake_g2 := ContentDefinitions.get_comprehension_question("elder_slime_dewdrop", "grade_2_mage")
    _check(failures, not keepsake_g2.is_empty(), "expected a grade_2_mage question for the elder_slime_dewdrop keepsake")

    var missing := ContentDefinitions.get_comprehension_question("no_such_entry", "grade_2_mage")
    _check(failures, missing.is_empty(), "expected an empty dictionary for an unknown entry")

    return {"ok": failures.is_empty(), "failures": failures}

func test_mark_comprehension_answered_is_idempotent_and_persists() -> Dictionary:
    var failures: Array[String] = []

    GameState.mark_comprehension_answered("meadow_slime")
    GameState.mark_comprehension_answered("meadow_slime")
    _check(failures, GameState.has_answered_comprehension("meadow_slime"), "expected meadow_slime marked answered")
    _check(failures, GameState.comprehension_answered.size() == 1, "expected exactly one answered entry, got %d" % GameState.comprehension_answered.size())

    GameState.comprehension_answered = {}
    GameState.load_game()
    _check(failures, GameState.has_answered_comprehension("meadow_slime"), "comprehension_answered did not survive save/load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_award_comprehension_bonus_fires_signal_and_never_blocks() -> Dictionary:
    var failures: Array[String] = []
    _bonus_awarded_count = 0
    _last_bonus_entry_id = ""

    GameState.comprehension_bonus_awarded.connect(_on_comprehension_bonus_awarded_probe)
    GameState.award_comprehension_bonus("meadow_slime")
    GameState.comprehension_bonus_awarded.disconnect(_on_comprehension_bonus_awarded_probe)

    _check(failures, _bonus_awarded_count == 1, "expected comprehension_bonus_awarded to fire once, got %d" % _bonus_awarded_count)
    _check(failures, _last_bonus_entry_id == "meadow_slime", "expected signal arg meadow_slime, got %s" % _last_bonus_entry_id)

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_comprehension_answered() -> Dictionary:
    var failures: Array[String] = []

    GameState.mark_comprehension_answered("meadow_slime")
    GameState.reset_state()

    _check(failures, GameState.comprehension_answered.is_empty(), "reset_state left comprehension_answered populated")
    _check(failures, not GameState.has_answered_comprehension("meadow_slime"), "reset_state left meadow_slime recorded as answered")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
