extends RefCounted

## Second pet ("Dewdrop", expansion backlog "Second pet: earn a companion from the Elder Slime
## keepsake") tests. Isolated file (registered in tests/test_runner.gd), same conventions as
## tests/pet_tests.gd: each test_* runs against a freshly reset GameState singleton and returns
## {"ok": bool, "failures": Array[String]}.
##
## Deliberately does NOT extend tests/pet_tests.gd - Dewdrop's grant path is a different trigger
## (boss death, not the all-four-quests gate) with different auto-equip behavior, so keeping it
## isolated avoids coupling the two pets' test suites together.

func test_boss_death_grants_dewdrop_once_and_does_not_auto_equip() -> Dictionary:
    var failures: Array[String] = []

    GameState._check_and_grant_boss_pet()
    _check(failures, GameState.owns_pet("dewdrop"), "expected dewdrop owned after boss-pet grant")
    _check(failures, GameState.equipped_pet == "", "expected dewdrop grant to NOT auto-equip")

    # Re-running the grant path must not duplicate ownership (idempotent, mirrors
    # _check_and_grant_first_pet()'s precedent).
    GameState._check_and_grant_boss_pet()
    _check(failures, GameState.owned_pets.count("dewdrop") == 1, "boss-pet re-grant duplicated dewdrop")

    return {"ok": failures.is_empty(), "failures": failures}

func test_dewdrop_grant_does_not_change_hp() -> Dictionary:
    var failures: Array[String] = []

    var hp_before := GameState.player_hp
    GameState._check_and_grant_boss_pet()

    _check(failures, GameState.player_hp == hp_before,
        "expected dewdrop's unequipped grant to leave hp unchanged, was %d now %d" % [hp_before, GameState.player_hp])
    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP,
        "expected effective max hp unchanged while dewdrop isn't equipped")

    return {"ok": failures.is_empty(), "failures": failures}

func test_dewdrop_can_be_equipped_manually_with_its_own_bonus_and_no_auto_heal() -> Dictionary:
    var failures: Array[String] = []

    GameState._check_and_grant_boss_pet()
    GameState.take_player_damage(2)
    var hp_before := GameState.player_hp

    GameState.equip_pet("dewdrop")
    _check(failures, GameState.equipped_pet == "dewdrop", "expected dewdrop equipped")
    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP + 3,
        "expected dewdrop's +3 bonus, got effective max %d" % GameState.get_effective_max_hp())
    _check(failures, GameState.player_hp == hp_before,
        "manual equip must not auto-heal; hp should stay at %d, got %d" % [hp_before, GameState.player_hp])

    return {"ok": failures.is_empty(), "failures": failures}

func test_both_pets_can_coexist_and_swapping_clamps_hp_correctly() -> Dictionary:
    var failures: Array[String] = []

    # Grant both pets via their independent paths.
    GameState._check_and_grant_boss_pet()
    for quest_id in ["elder_golden_star", "mira_glowing_herb", "finn_shimmering_ore", "yarrow_silverleaf"]:
        GameState.complete_quest(quest_id)

    _check(failures, GameState.owns_pet("dewdrop"), "expected dewdrop owned")
    _check(failures, GameState.owns_pet("mossy"), "expected mossy owned")
    _check(failures, GameState.owned_pets.size() == 2, "expected exactly two owned pets, got %d" % GameState.owned_pets.size())
    # Mossy's grant auto-equips (unchanged precedent) and heals to its own max.
    _check(failures, GameState.equipped_pet == "mossy", "expected mossy auto-equipped by its own grant")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP + 2, "expected full hp at mossy's boosted max")

    # Swap to dewdrop (+3, a bigger bonus than mossy's +2): hp should carry over unclamped
    # since it's still within the new, larger max.
    GameState.equip_pet("dewdrop")
    _check(failures, GameState.equipped_pet == "dewdrop", "expected dewdrop equipped after swap")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP + 2,
        "expected hp to carry over unclamped when swapping to a bigger bonus, got %d" % GameState.player_hp)

    # Swap back to mossy (+2, a smaller bonus): hp must clamp down to the new, smaller max.
    GameState.equip_pet("mossy")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP + 2,
        "expected hp clamped to mossy's smaller max, got %d" % GameState.player_hp)

    # Unequip entirely: hp clamps down to the base max.
    GameState.equip_pet("")
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP,
        "expected hp clamped to base max after unequip, got %d" % GameState.player_hp)

    return {"ok": failures.is_empty(), "failures": failures}

func test_dewdrop_survives_save_load_and_reset() -> Dictionary:
    var failures: Array[String] = []

    GameState._check_and_grant_boss_pet()
    GameState.equip_pet("dewdrop")
    GameState.save_game()

    GameState.owned_pets = []
    GameState.equipped_pet = ""
    GameState.load_game()

    _check(failures, GameState.owns_pet("dewdrop"), "owned_pets did not survive save/load")
    _check(failures, GameState.equipped_pet == "dewdrop", "equipped_pet did not survive save/load")

    GameState.reset_state()
    _check(failures, GameState.owned_pets.is_empty(), "reset_state left owned_pets populated")
    _check(failures, GameState.equipped_pet == "", "reset_state left a pet equipped")
    _check(failures, GameState.get_effective_max_hp() == GameState.PLAYER_MAX_HP,
        "reset_state left a boosted max hp")

    return {"ok": failures.is_empty(), "failures": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
