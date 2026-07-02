extends RefCounted

## "Creatures met" codex tests. Isolated file (registered in tests/test_runner.gd) per the
## conductor directive: new tests avoid the game_state_tests.gd merge hotspot.
## Same conventions: each test_* runs against a freshly reset GameState singleton and
## returns {"ok": bool, "failures": Array[String]}. Named signal-probe methods, not lambdas
## - a lambda connected to a GameState signal does not reliably fire on this Godot 4.7 build
## (see the note at the top of tests/game_state_tests.gd).

var _creature_met_count: int = 0
var _last_creature_met_id: String = ""

func _on_creature_met_probe(creature_id: String) -> void:
    _creature_met_count += 1
    _last_creature_met_id = creature_id

func test_first_meet_records_and_fires_signal_once() -> Dictionary:
    var failures: Array[String] = []
    _creature_met_count = 0
    _last_creature_met_id = ""

    GameState.creature_met.connect(_on_creature_met_probe)
    GameState.record_creature_met("meadow_slime")
    GameState.creature_met.disconnect(_on_creature_met_probe)

    _check(failures, GameState.has_met_creature("meadow_slime"), "expected meadow_slime recorded as met")
    _check(failures, _creature_met_count == 1, "expected creature_met to fire once, got %d" % _creature_met_count)
    _check(failures, _last_creature_met_id == "meadow_slime", "expected signal arg meadow_slime, got %s" % _last_creature_met_id)

    return {"ok": failures.is_empty(), "failures": failures}

func test_repeat_meet_is_idempotent() -> Dictionary:
    var failures: Array[String] = []
    _creature_met_count = 0

    GameState.creature_met.connect(_on_creature_met_probe)
    GameState.record_creature_met("meadow_slime")
    GameState.record_creature_met("meadow_slime")
    GameState.record_creature_met("meadow_slime")
    GameState.creature_met.disconnect(_on_creature_met_probe)

    _check(failures, _creature_met_count == 1, "expected signal count to stay 1 on repeat meets, got %d" % _creature_met_count)
    _check(failures, GameState.has_met_creature("meadow_slime"), "expected meadow_slime still recorded as met")

    return {"ok": failures.is_empty(), "failures": failures}

func test_creatures_met_survives_save_and_load_round_trip() -> Dictionary:
    var failures: Array[String] = []

    GameState.record_creature_met("meadow_slime")
    GameState.save_game()

    # Wipe in-memory state without touching the save file, then reload.
    GameState.creatures_met = {}
    GameState.load_game()

    _check(failures, GameState.has_met_creature("meadow_slime"), "creatures_met did not survive save/load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_creatures_met() -> Dictionary:
    var failures: Array[String] = []

    GameState.record_creature_met("meadow_slime")
    GameState.reset_state()

    _check(failures, GameState.creatures_met.is_empty(), "reset_state left creatures_met populated")
    _check(failures, not GameState.has_met_creature("meadow_slime"), "reset_state left meadow_slime recorded as met")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
