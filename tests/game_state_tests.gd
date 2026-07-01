extends RefCounted

## Each test_* method runs against a freshly GameState.reset_state()'d singleton
## (see tests/test_runner.gd) and returns {"ok": bool, "failures": Array[String]}.
##
## Signal probes here use a NAMED method (e.g. _on_armor_probe) rather than a local lambda,
## deliberately. A lambda connected to a GameState signal from this RefCounted test suite
## did not reliably fire on this Godot 4.7 build, even though the identical signal correctly
## reached a named bound method - confirmed by connecting both to armor_equipped at once and
## observing the named method fire while the lambda stayed silent. Root cause not fully
## diagnosed; treat lambdas connected to cross-object signals as unreliable in this codebase
## until it is.

func test_quest_lifecycle_progresses_through_states() -> Dictionary:
    var failures: Array[String] = []
    var quest_id := GameState.QUEST_ELDER_GOLDEN_STAR

    _check(failures, GameState.get_quest_state(quest_id) == GameState.QUEST_NOT_STARTED, "expected not_started at start")

    GameState.start_quest(quest_id)
    _check(failures, GameState.get_quest_state(quest_id) == GameState.QUEST_STARTED, "expected started after start_quest")

    GameState.mark_quest_ready_to_turn_in(quest_id)
    _check(failures, GameState.get_quest_state(quest_id) == GameState.QUEST_READY_TO_TURN_IN, "expected ready_to_turn_in")

    GameState.start_learning_check(quest_id)
    _check(failures, GameState.get_quest_state(quest_id) == GameState.QUEST_LEARNING_CHECK, "expected learning_check")

    GameState.complete_quest(quest_id)
    _check(failures, GameState.get_quest_state(quest_id) == GameState.QUEST_COMPLETED, "expected completed")

    return {"ok": failures.is_empty(), "failures": failures}

func test_complete_quest_is_idempotent() -> Dictionary:
    # Self-validating: also asserts the probe fires exactly once for the real completion,
    # so a probe that silently never fires at all can't masquerade as "correctly idempotent".
    var failures: Array[String] = []
    var quest_id := GameState.QUEST_MIRA_GLOWING_HERB

    _quest_changed_signal_count = 0
    GameState.quest_changed.connect(_on_quest_changed_probe)

    GameState.complete_quest(quest_id)
    _check(failures, _quest_changed_signal_count == 1,
        "expected quest_changed to fire once for the real completion, fired %d time(s)" % _quest_changed_signal_count)

    GameState.complete_quest(quest_id)
    _check(failures, _quest_changed_signal_count == 1,
        "completing an already-completed quest changed the fire count to %d" % _quest_changed_signal_count)

    GameState.quest_changed.disconnect(_on_quest_changed_probe)

    return {"ok": failures.is_empty(), "failures": failures}

func test_add_item_marks_matching_started_quest_ready() -> Dictionary:
    var failures: Array[String] = []

    GameState.start_quest(GameState.QUEST_ELDER_GOLDEN_STAR)
    GameState.add_item("golden_star")

    _check(failures, GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR) == GameState.QUEST_READY_TO_TURN_IN,
        "expected elder quest ready_to_turn_in after collecting golden_star")
    _check(failures, GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB) == GameState.QUEST_NOT_STARTED,
        "expected mira quest untouched by a golden_star pickup")
    _check(failures, GameState.has_item("golden_star"), "expected has_item(golden_star) true after add_item")

    return {"ok": failures.is_empty(), "failures": failures}

func test_add_item_marks_yarrow_quest_ready() -> Dictionary:
    var failures: Array[String] = []

    GameState.start_quest(GameState.QUEST_YARROW_SILVERLEAF)
    GameState.add_item("silverleaf")

    _check(failures, GameState.get_quest_state(GameState.QUEST_YARROW_SILVERLEAF) == GameState.QUEST_READY_TO_TURN_IN,
        "expected yarrow quest ready_to_turn_in after collecting silverleaf")
    _check(failures, GameState.has_item("silverleaf"), "expected has_item(silverleaf) true after add_item")

    return {"ok": failures.is_empty(), "failures": failures}

func test_quest_bonus_tracking() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, not GameState.has_quest_bonus(GameState.QUEST_FINN_SHIMMERING_ORE), "expected no bonus by default")
    GameState.award_quest_bonus(GameState.QUEST_FINN_SHIMMERING_ORE)
    _check(failures, GameState.has_quest_bonus(GameState.QUEST_FINN_SHIMMERING_ORE), "expected bonus after award_quest_bonus")

    return {"ok": failures.is_empty(), "failures": failures}

func test_completing_all_quests_grants_armor_exactly_once_regardless_of_order() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, GameState.equipped_armor_tier == 0, "expected no armor before any quest completes")

    # Deliberately not the "natural" Elder -> Mira -> Finn -> Yarrow order, to prove the
    # grant check is order-independent.
    GameState.complete_quest(GameState.QUEST_FINN_SHIMMERING_ORE)
    _check(failures, GameState.equipped_armor_tier == 0, "expected no armor after only 1/4 quests")

    GameState.complete_quest(GameState.QUEST_YARROW_SILVERLEAF)
    _check(failures, GameState.equipped_armor_tier == 0, "expected no armor after only 2/4 quests")

    GameState.complete_quest(GameState.QUEST_MIRA_GLOWING_HERB)
    _check(failures, GameState.equipped_armor_tier == 0, "expected no armor after only 3/4 quests")

    _armor_signal_count = 0
    GameState.armor_equipped.connect(_on_armor_probe)
    GameState.complete_quest(GameState.QUEST_ELDER_GOLDEN_STAR)
    GameState.armor_equipped.disconnect(_on_armor_probe)

    _check(failures, GameState.equipped_armor_tier == 1, "expected tier 1 armor after all 4 quests complete")
    _check(failures, _armor_signal_count == 1, "expected armor_equipped to fire exactly once, fired %d time(s)" % _armor_signal_count)

    return {"ok": failures.is_empty(), "failures": failures}

func test_save_and_load_round_trip() -> Dictionary:
    var failures: Array[String] = []

    GameState.set_selected_profile("grade_5_adventurer")
    GameState.add_item("shimmering_ore")
    # Bonus has no dedicated signal, so it only reaches disk via a later signal-emitting
    # call (matches LearningCheck.gd's real award-then-complete order) - award before
    # complete_quest, not after, or this assertion would read stale disk content.
    GameState.award_quest_bonus(GameState.QUEST_MIRA_GLOWING_HERB)
    GameState.complete_quest(GameState.QUEST_MIRA_GLOWING_HERB)

    var saved_profile := GameState.selected_profile
    var saved_items := GameState.collected_items.duplicate(true)
    var saved_quests := GameState.quest_states.duplicate(true)
    var saved_bonuses := GameState.quest_bonuses.duplicate(true)
    var saved_armor := GameState.equipped_armor_tier

    # Simulate a fresh process: wipe in-memory state, then load whatever autosave wrote.
    GameState.selected_profile = ""
    GameState.collected_items = {}
    GameState.quest_states = {
        GameState.QUEST_ELDER_GOLDEN_STAR: GameState.QUEST_NOT_STARTED,
        GameState.QUEST_MIRA_GLOWING_HERB: GameState.QUEST_NOT_STARTED,
        GameState.QUEST_FINN_SHIMMERING_ORE: GameState.QUEST_NOT_STARTED,
        GameState.QUEST_YARROW_SILVERLEAF: GameState.QUEST_NOT_STARTED,
    }
    GameState.quest_bonuses = {}
    GameState.equipped_armor_tier = 0

    GameState.load_game()

    _check(failures, GameState.selected_profile == saved_profile, "profile mismatch after load")
    _check(failures, GameState.collected_items == saved_items, "collected_items mismatch after load")
    _check(failures, GameState.quest_states == saved_quests, "quest_states mismatch after load")
    _check(failures, GameState.quest_bonuses == saved_bonuses, "quest_bonuses mismatch after load")
    _check(failures, GameState.equipped_armor_tier == saved_armor, "equipped_armor_tier mismatch after load")

    return {"ok": failures.is_empty(), "failures": failures}

func test_load_game_is_a_no_op_when_no_save_file_exists() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, not FileAccess.file_exists(GameState.SAVE_PATH), "expected no save file right after reset_state()")

    # Should not crash and should leave the freshly-reset defaults untouched.
    GameState.load_game()

    _check(failures, GameState.selected_profile == "", "expected profile to remain empty")
    _check(failures, GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR) == GameState.QUEST_NOT_STARTED,
        "expected quest state to remain not_started")

    return {"ok": failures.is_empty(), "failures": failures}

func test_reset_state_clears_all_state_and_deletes_save_file() -> Dictionary:
    # reset_progress() = reset_state() + a conditional scene reload; this test covers the
    # state-clearing half in isolation. The reload half is covered by the manual save/load
    # playtest checklist in docs/CURRENT_STATE.md (also live-verified via real mouse clicks
    # when the equip/reset UI shipped), since a headless test runner has no meaningful scene
    # of its own to reload.
    var failures: Array[String] = []

    GameState.set_selected_profile("grade_2_mage")
    GameState.add_item("golden_star")
    GameState.complete_quest(GameState.QUEST_ELDER_GOLDEN_STAR)
    GameState.equipped_armor_tier = 1
    GameState.save_game()
    _check(failures, FileAccess.file_exists(GameState.SAVE_PATH), "expected a save file to exist before reset")

    GameState.reset_state()

    _check(failures, GameState.selected_profile == "", "expected empty profile after reset")
    _check(failures, GameState.collected_items.is_empty(), "expected no collected items after reset")
    _check(failures, GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR) == GameState.QUEST_NOT_STARTED,
        "expected elder quest reset to not_started")
    _check(failures, GameState.equipped_armor_tier == 0, "expected armor tier reset to 0")
    _check(failures, not FileAccess.file_exists(GameState.SAVE_PATH), "expected save file deleted after reset")

    return {"ok": failures.is_empty(), "failures": failures}

func test_combat_multiplier_stacks_correct_answers_and_caps() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, GameState.get_combat_multiplier() == 1.0, "expected 1x multiplier with no streak")

    GameState.answer_combat_question(true)
    _check(failures, GameState.get_combat_multiplier() == 1.5, "expected 1.5x after 1 correct answer")

    GameState.answer_combat_question(true)
    _check(failures, GameState.get_combat_multiplier() == 2.0, "expected 2x after 2 correct answers")

    GameState.answer_combat_question(true)
    _check(failures, GameState.get_combat_multiplier() == 2.5, "expected 2.5x after 3 correct answers")

    # Streak is capped at COMBAT_STREAK_MAX (3) - a 4th correct answer should not push higher.
    GameState.answer_combat_question(true)
    _check(failures, GameState.get_combat_multiplier() == 2.5, "expected multiplier to stay capped at 2.5x")

    # A wrong answer never reduces the streak - bonus-only, matches the North Star rule.
    GameState.answer_combat_question(false)
    _check(failures, GameState.get_combat_multiplier() == 2.5, "expected a wrong answer to leave the streak untouched")

    return {"ok": failures.is_empty(), "failures": failures}

func test_combat_question_cooldown_gates_retrigger() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, GameState.can_trigger_combat_question(), "expected a question to be triggerable by default")

    GameState.mark_combat_question_triggered()
    _check(failures, not GameState.can_trigger_combat_question(), "expected cooldown to block an immediate retrigger")

    return {"ok": failures.is_empty(), "failures": failures}

func test_take_player_damage_respects_hit_cooldown_and_heals_to_full() -> Dictionary:
    var failures: Array[String] = []

    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP, "expected full hp at start")

    GameState.take_player_damage(2)
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP - 2, "expected hp reduced by 2")

    # Immediate second hit within the same instant is blocked by the hit-cooldown - standing
    # in continuous contact with an enemy shouldn't deal damage every physics frame.
    GameState.take_player_damage(2)
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP - 2, "expected the immediate second hit to be ignored")

    GameState.heal_player_to_full()
    _check(failures, GameState.player_hp == GameState.PLAYER_MAX_HP, "expected hp restored to full")

    return {"ok": failures.is_empty(), "failures": failures}

func test_take_player_damage_at_zero_hp_fires_died_exactly_once() -> Dictionary:
    var failures: Array[String] = []

    _player_died_signal_count = 0
    GameState.player_died.connect(_on_player_died_probe)

    GameState.take_player_damage(GameState.PLAYER_MAX_HP)
    _check(failures, GameState.player_hp == 0, "expected hp to reach 0")
    _check(failures, _player_died_signal_count == 1, "expected player_died to fire exactly once, fired %d time(s)" % _player_died_signal_count)

    GameState.player_died.disconnect(_on_player_died_probe)

    return {"ok": failures.is_empty(), "failures": failures}

static func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

var _armor_signal_count := 0

func _on_armor_probe(_tier: int) -> void:
    _armor_signal_count += 1

var _quest_changed_signal_count := 0

func _on_quest_changed_probe(_quest_id: String, _state: String) -> void:
    _quest_changed_signal_count += 1

var _player_died_signal_count := 0

func _on_player_died_probe() -> void:
    _player_died_signal_count += 1
