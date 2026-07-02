extends Node

const GameStateTests := preload("res://tests/game_state_tests.gd")
const HitFlashTests := preload("res://tests/hit_flash_tests.gd")
const PetTests := preload("res://tests/pet_tests.gd")

var _pass_count := 0
var _fail_count := 0

func _ready() -> void:
    print("=== Eldoria-Godot GDScript test suite ===")
    _run_suite("GameStateTests", GameStateTests.new())
    _run_suite("HitFlashTests", HitFlashTests.new())
    _run_suite("PetTests", PetTests.new())
    print("")
    print("%d passed, %d failed" % [_pass_count, _fail_count])
    get_tree().quit(1 if _fail_count > 0 else 0)

func _run_suite(suite_name: String, suite: Object) -> void:
    for method in suite.get_method_list():
        var method_name: String = method["name"]
        if not method_name.begins_with("test_"):
            continue

        GameState.reset_state()
        var result: Dictionary = suite.call(method_name)

        if result.get("ok", false):
            _pass_count += 1
            print("  [PASS] %s.%s" % [suite_name, method_name])
        else:
            _fail_count += 1
            print("  [FAIL] %s.%s" % [suite_name, method_name])
            for failure in result.get("failures", []):
                print("         - %s" % failure)
