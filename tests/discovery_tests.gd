extends RefCounted

## "Places discovered" codex tests (Discovery sparkle-spots slice). Isolated file
## (registered in tests/test_runner.gd), mirroring tests/codex_tests.gd exactly. Each
## test_* runs against a freshly reset GameState singleton and returns
## {"ok": bool, "failures": Array[String]}. Named signal-probe methods, not lambdas - a
## lambda connected to a GameState signal does not reliably fire on this Godot 4.7 build
## (see the note at the top of tests/game_state_tests.gd).

var _place_discovered_count: int = 0
var _last_place_discovered_id: String = ""

func _on_place_discovered_probe(place_id: String) -> void:
    _place_discovered_count += 1
    _last_place_discovered_id = place_id

func test_first_discovery_records_and_fires_signal_once() -> Dictionary:
    var failures: Array[String] = []
    _place_discovered_count = 0
    _last_place_discovered_id = ""

    GameState.place_discovered.connect(_on_place_discovered_probe)
    GameState.discover_place("flower_meadow_sparkle")
    GameState.place_discovered.disconnect(_on_place_discovered_probe)

    _check(failures, GameState.has_discovered_place("flower_meadow_sparkle"), "expected flower_meadow_sparkle recorded as discovered")
    _check(failures, _place_discovered_count == 1, "expected place_discovered to fire once, got %d" % _place_discovered_count)
    _check(failures, _last_place_discovered_id == "flower_meadow_sparkle", "expected signal arg flower_meadow_sparkle, got %s" % _last_place_discovered_id)

    return {"ok": failures.is_empty(), "failures": failures}

func test_repeat_discovery_is_idempotent() -> Dictionary:
    var failures: Array[String] = []
    _place_discovered_count = 0

    GameState.place_discovered.connect(_on_place_discovered_probe)
    GameState.discover_place("flower_meadow_sparkle")
    GameState.discover_place("flower_meadow_sparkle")
    GameState.discover_place("flower_meadow_sparkle")
    GameState.place_discovered.disconnect(_on_place_discovered_probe)

    _check(failures, _place_discovered_count == 1, "expected signal count to stay 1 on repeat discoveries, got %d" % _place_discovered_count)
    _check(failures, GameState.has_discovered_place("flower_meadow_sparkle"), "expected flower_meadow_sparkle still recorded as discovered")

    return {"ok": failures.is_empty(), "failures": failures}

func test_places_discovered_survives_save_and_load_round_trip() -> Dictionary:
    var failures: Array[String] = []

    GameState.discover_place("flower_meadow_sparkle")
    GameState.save_game()

    # Wipe in-memory state without touching the save file, then reload.
    GameState.places_discovered = {}
    GameState.load_game()

    _check(failures, GameState.has_discovered_place("flower_meadow_sparkle"), "places_discovered did not survive save/load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_places_discovered() -> Dictionary:
    var failures: Array[String] = []

    GameState.discover_place("flower_meadow_sparkle")
    GameState.reset_state()

    _check(failures, GameState.places_discovered.is_empty(), "reset_state left places_discovered populated")
    _check(failures, not GameState.has_discovered_place("flower_meadow_sparkle"), "reset_state left flower_meadow_sparkle recorded as discovered")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
