extends RefCounted

## Campfire rest-beat tests. Isolated file (registered in tests/test_runner.gd), mirroring
## tests/elder_slime_tests.gd's shape for testing a pure static function preloaded directly
## from the scene script - Campfire.get_rest_message() picks the profile-aware rest line and
## has no scene-tree/RNG dependency, so it's tested standalone without instancing the scene.

const Campfire := preload("res://scripts/props/Campfire.gd")

func test_grade_2_gets_short_plain_message() -> Dictionary:
    var failures: Array[String] = []

    var message := Campfire.get_rest_message("grade_2_mage")

    _check(failures, message == "You rest by the warm fire. Your adventure is saved! See you next time!",
        "unexpected grade 2 rest message: %s" % message)

    return {"ok": failures.is_empty(), "failures": failures}

func test_grade_5_gets_a_different_richer_message() -> Dictionary:
    var failures: Array[String] = []

    var grade2_message := Campfire.get_rest_message("grade_2_mage")
    var grade5_message := Campfire.get_rest_message("grade_5_adventurer")

    _check(failures, grade5_message != grade2_message,
        "expected grade 5 rest message to differ from grade 2's")
    _check(failures, grade5_message.length() > grade2_message.length(),
        "expected grade 5 rest message to be richer/longer than grade 2's")

    return {"ok": failures.is_empty(), "failures": failures}

func test_unknown_profile_falls_back_to_a_neutral_message() -> Dictionary:
    var failures: Array[String] = []

    var message := Campfire.get_rest_message("")

    _check(failures, message == "You rest by the warm fire. Your progress is saved.",
        "unexpected fallback rest message: %s" % message)

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
