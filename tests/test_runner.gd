extends Node

const GameStateTests := preload("res://tests/game_state_tests.gd")
const HitFlashTests := preload("res://tests/hit_flash_tests.gd")
const PetTests := preload("res://tests/pet_tests.gd")
const SpawnerTests := preload("res://tests/spawner_tests.gd")
const AudioTests := preload("res://tests/audio_tests.gd")
const CodexTests := preload("res://tests/codex_tests.gd")
const ElderSlimeTests := preload("res://tests/elder_slime_tests.gd")
const KeepsakeTests := preload("res://tests/keepsake_tests.gd")
const MapTests := preload("res://tests/map_tests.gd")
const CampfireTests := preload("res://tests/campfire_tests.gd")
const DiscoveryTests := preload("res://tests/discovery_tests.gd")
const CoinCountingTests := preload("res://tests/coin_counting_tests.gd")
const AtmosphereTests := preload("res://tests/atmosphere_tests.gd")
const LakeTests := preload("res://tests/lake_tests.gd")
const ComprehensionTests := preload("res://tests/comprehension_tests.gd")
const ParticleTests := preload("res://tests/particle_tests.gd")

var _pass_count := 0
var _fail_count := 0

func _ready() -> void:
    print("=== Eldoria-Godot GDScript test suite ===")
    _run_suite("GameStateTests", GameStateTests.new())
    _run_suite("HitFlashTests", HitFlashTests.new())
    _run_suite("PetTests", PetTests.new())
    _run_suite("SpawnerTests", SpawnerTests.new())
    _run_suite("AudioTests", AudioTests.new())
    _run_suite("CodexTests", CodexTests.new())
    _run_suite("ElderSlimeTests", ElderSlimeTests.new())
    _run_suite("KeepsakeTests", KeepsakeTests.new())
    _run_suite("MapTests", MapTests.new())
    _run_suite("CampfireTests", CampfireTests.new())
    _run_suite("DiscoveryTests", DiscoveryTests.new())
    _run_suite("CoinCountingTests", CoinCountingTests.new())
    _run_suite("AtmosphereTests", AtmosphereTests.new())
    _run_suite("LakeTests", LakeTests.new())
    _run_suite("ComprehensionTests", ComprehensionTests.new())
    _run_suite("ParticleTests", ParticleTests.new())
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
