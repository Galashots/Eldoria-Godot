extends RefCounted

## Boss keepsake tests. Isolated file (registered in tests/test_runner.gd), mirroring
## tests/codex_tests.gd's shape exactly - keepsakes.gd is a permanent-trophy sibling of the
## "Creatures met" codex. Each test_* runs against a freshly reset GameState singleton and
## returns {"ok": bool, "failures": Array[String]}. Named signal-probe methods, not lambdas -
## a lambda connected to a GameState signal does not reliably fire on this Godot 4.7 build
## (see the note at the top of tests/game_state_tests.gd).

var _keepsake_awarded_count: int = 0
var _last_keepsake_id: String = ""

func _on_keepsake_awarded_probe(keepsake_id: String) -> void:
    _keepsake_awarded_count += 1
    _last_keepsake_id = keepsake_id

func test_first_award_records_and_fires_signal_once() -> Dictionary:
    var failures: Array[String] = []
    _keepsake_awarded_count = 0
    _last_keepsake_id = ""

    GameState.keepsake_awarded.connect(_on_keepsake_awarded_probe)
    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.keepsake_awarded.disconnect(_on_keepsake_awarded_probe)

    _check(failures, GameState.has_keepsake("elder_slime_dewdrop"), "expected elder_slime_dewdrop recorded as earned")
    _check(failures, _keepsake_awarded_count == 1, "expected keepsake_awarded to fire once, got %d" % _keepsake_awarded_count)
    _check(failures, _last_keepsake_id == "elder_slime_dewdrop", "expected signal arg elder_slime_dewdrop, got %s" % _last_keepsake_id)

    return {"ok": failures.is_empty(), "failures": failures}

func test_repeat_award_is_idempotent() -> Dictionary:
    var failures: Array[String] = []
    _keepsake_awarded_count = 0

    GameState.keepsake_awarded.connect(_on_keepsake_awarded_probe)
    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.keepsake_awarded.disconnect(_on_keepsake_awarded_probe)

    _check(failures, _keepsake_awarded_count == 1, "expected signal count to stay 1 on repeat awards, got %d" % _keepsake_awarded_count)
    _check(failures, GameState.has_keepsake("elder_slime_dewdrop"), "expected elder_slime_dewdrop still recorded as earned")

    return {"ok": failures.is_empty(), "failures": failures}

func test_keepsakes_survive_save_and_load_round_trip() -> Dictionary:
    var failures: Array[String] = []

    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.save_game()

    # Wipe in-memory state without touching the save file, then reload.
    GameState.keepsakes = {}
    GameState.load_game()

    _check(failures, GameState.has_keepsake("elder_slime_dewdrop"), "keepsakes did not survive save/load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_keepsakes() -> Dictionary:
    var failures: Array[String] = []

    GameState.award_keepsake("elder_slime_dewdrop")
    GameState.reset_state()

    _check(failures, GameState.keepsakes.is_empty(), "reset_state left keepsakes populated")
    _check(failures, not GameState.has_keepsake("elder_slime_dewdrop"), "reset_state left elder_slime_dewdrop recorded as earned")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
