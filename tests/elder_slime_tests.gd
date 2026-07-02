extends RefCounted

## First mini-boss tests (expansion backlog slice). Isolated file (registered in
## tests/test_runner.gd), same conventions as tests/pet_tests.gd/spawner_tests.gd: each
## test_* returns {"ok": bool, "failures": Array[String]}. Covers the pure logic the slice
## added - the telegraphed-lunge windup easing (mirrors HealthComponent's
## hit_reaction_intensity() precedent) and the codex fact entry - plus the tuned stat
## overrides baked into ElderSlime.tscn, read via a temporary scene instance rather than
## hardcoded scene-tree assertions elsewhere.

const ElderSlime := preload("res://scripts/enemies/ElderSlime.gd")
const ElderSlimeScene := preload("res://scenes/enemies/ElderSlime.tscn")

func test_telegraph_windup_intensity_ramps_from_zero_to_one() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, ElderSlime.telegraph_windup_intensity(0.8, 0.8) == 0.0,
        "expected zero intensity at the very start of the windup")
    _check(failures, ElderSlime.telegraph_windup_intensity(0.0, 0.8) == 1.0,
        "expected full intensity the instant the windup completes")
    _check(failures, ElderSlime.telegraph_windup_intensity(0.4, 0.8) == 0.5,
        "expected halfway intensity at the midpoint of the windup")

    return {"ok": failures.is_empty(), "failures": failures}

func test_telegraph_windup_intensity_handles_zero_duration() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, ElderSlime.telegraph_windup_intensity(0.0, 0.0) == 1.0,
        "expected a zero-duration windup to report full intensity immediately, not divide by zero")

    return {"ok": failures.is_empty(), "failures": failures}

func test_elder_slime_is_tougher_than_meadow_slime() -> Dictionary:
    var failures: Array[String] = []
    var instance := ElderSlimeScene.instantiate()

    var health := instance.get_node("HealthComponent")
    _check(failures, health.max_hp > 3,
        "expected Elder Slime's max_hp (%d) to exceed the base Meadow Slime's 3 hp" % health.max_hp)
    _check(failures, instance.move_speed < 40.0,
        "expected Elder Slime to move slower than the base Meadow Slime (40.0) so its telegraph reads clearly, got %f" % instance.move_speed)
    _check(failures, instance.coin_drop_value > 1,
        "expected Elder Slime's guaranteed coin drop to exceed the base Meadow Slime's 1, got %d" % instance.coin_drop_value)
    _check(failures, instance.bonus_coin_chance > 0.12,
        "expected Elder Slime's bonus coin chance to exceed the base Meadow Slime's 0.12, got %f" % instance.bonus_coin_chance)

    instance.free()
    return {"ok": failures.is_empty(), "failures": failures}

func test_codex_has_a_friendly_elder_slime_fact() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, ContentDefinitions.get_creature_label("elder_slime") == "Elder Slime",
        "expected the codex label for elder_slime to be 'Elder Slime'")
    _check(failures, not ContentDefinitions.get_creature_fact("elder_slime").is_empty(),
        "expected a non-empty codex fact for elder_slime")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
