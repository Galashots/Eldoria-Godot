extends RefCounted

## M4 pet system tests. Isolated file (registered in tests/test_runner.gd) per the
## conductor directive: new tests avoid the game_state_tests.gd merge hotspot.
## Same conventions: each test_* runs against a freshly reset GameState singleton and
## returns {"ok": bool, "failures": Array[String]}.

const ALL_QUESTS := [
    "elder_golden_star",
    "mira_glowing_herb",
    "finn_shimmering_ore",
    "yarrow_silverleaf",
]

func _complete_all_quests() -> void:
    for quest_id in ALL_QUESTS:
        GameState.complete_quest(quest_id)

func test_pet_grants_only_after_all_four_quests() -> Dictionary:
    var failures: Array[String] = []

    for i in range(ALL_QUESTS.size()):
        GameState.complete_quest(ALL_QUESTS[i])
        if i < ALL_QUESTS.size() - 1:
            _check(failures, GameState.owned_pets.is_empty(),
                "pet granted after only %d quest(s)" % (i + 1))

    _check(failures, GameState.owns_pet("mossy"), "expected mossy owned after all 4 quests")
    _check(failures, GameState.equipped_pet == "mossy", "expected mossy auto-equipped on grant")
    _check(failures, GameState.owned_pets.size() == 1, "expected exactly one owned pet")

    return {"ok": failures.is_empty(), "failures": failures}

func test_pet_grant_heals_by_bonus_and_is_idempotent() -> Dictionary:
    var failures: Array[String] = []

    GameState.take_player_damage(2)
    var hp_before := GameState.player_hp
    _complete_all_quests()

    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP + 2,
        "expected effective max hp %d, got %d" % [GameState.PLAYER_MAX_HP + 2, GameState.get_effective_max_hp()])
    _check(failures, GameState.player_hp == hp_before + 2,
        "expected grant to heal by the pet bonus (from %d to %d), got %d" % [hp_before, hp_before + 2, GameState.player_hp])

    # Re-running the granting path must not duplicate ownership.
    GameState._check_and_grant_first_pet()
    _check(failures, GameState.owned_pets.size() == 1, "grant re-check duplicated the pet")

    return {"ok": failures.is_empty(), "failures": failures}

func test_equip_pet_requires_ownership_and_unequip_clamps_hp() -> Dictionary:
    var failures: Array[String] = []

    GameState.equip_pet("mossy")
    _check(failures, GameState.equipped_pet == "", "equipping an unowned pet should be refused")

    _complete_all_quests()
    GameState.heal_player_to_full()
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP + 2, "expected full hp at boosted max")

    GameState.equip_pet("")
    _check(failures, GameState.equipped_pet == "", "expected unequip via empty id")
    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP,
        "expected base max hp after unequip")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP,
        "expected hp clamped to base max after unequip, got %d" % GameState.player_hp)

    GameState.equip_pet("mossy")
    _check(failures, GameState.equipped_pet == "mossy", "expected re-equip of owned pet")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP,
        "re-equip must not auto-heal; hp should stay at %d, got %d" % [GameState.PLAYER_MAX_HP, GameState.player_hp])

    return {"ok": failures.is_empty(), "failures": failures}

func test_pets_survive_save_and_load_round_trip() -> Dictionary:
    var failures: Array[String] = []

    _complete_all_quests()
    GameState.save_game()

    # Wipe in-memory state without touching the save file, then reload.
    GameState.owned_pets = []
    GameState.equipped_pet = ""
    GameState.load_game()

    _check(failures, GameState.owns_pet("mossy"), "owned_pets did not survive save/load")
    _check(failures, GameState.equipped_pet == "mossy", "equipped_pet did not survive save/load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_pets() -> Dictionary:
    var failures: Array[String] = []

    _complete_all_quests()
    GameState.reset_state()

    _check(failures, GameState.owned_pets.is_empty(), "reset_state left owned_pets populated")
    _check(failures, GameState.equipped_pet == "", "reset_state left a pet equipped")
    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP,
        "reset_state left a boosted max hp")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
