extends Node

signal item_added(item_id: String, amount: int)
signal elder_quest_changed
signal profile_changed(profile_id: String)
signal quest_changed(quest_id: String, state: String)
signal armor_equipped(tier: int)

const SAVE_PATH := "user://savegame.json"

const QUEST_ELDER_GOLDEN_STAR := "elder_golden_star"
const QUEST_MIRA_GLOWING_HERB := "mira_glowing_herb"
const QUEST_FINN_SHIMMERING_ORE := "finn_shimmering_ore"

const QUEST_NOT_STARTED := "not_started"
const QUEST_STARTED := "started"
const QUEST_READY_TO_TURN_IN := "ready_to_turn_in"
const QUEST_LEARNING_CHECK := "learning_check"
const QUEST_COMPLETED := "completed"

var selected_profile: String = ""
var player_hp: int = 5
var collected_items: Dictionary = {}
var quest_states: Dictionary = {
    QUEST_ELDER_GOLDEN_STAR: QUEST_NOT_STARTED,
    QUEST_MIRA_GLOWING_HERB: QUEST_NOT_STARTED,
    QUEST_FINN_SHIMMERING_ORE: QUEST_NOT_STARTED,
}
var quest_bonuses: Dictionary = {}
var equipped_armor_tier: int = 0

var elder_quest_started: bool = false
var elder_quest_completed: bool = false

func _ready() -> void:
    profile_changed.connect(_on_profile_changed_autosave)
    quest_changed.connect(_on_quest_changed_autosave)
    item_added.connect(_on_item_added_autosave)
    armor_equipped.connect(_on_armor_equipped_autosave)
    load_game()

func set_selected_profile(profile_id: String) -> void:
    selected_profile = profile_id
    profile_changed.emit(profile_id)

func add_item(item_id: String, amount: int = 1) -> void:
    collected_items[item_id] = collected_items.get(item_id, 0) + amount
    item_added.emit(item_id, amount)

    if item_id == "golden_star" and get_quest_state(QUEST_ELDER_GOLDEN_STAR) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_ELDER_GOLDEN_STAR)
    elif item_id == "glowing_herb" and get_quest_state(QUEST_MIRA_GLOWING_HERB) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_MIRA_GLOWING_HERB)
    elif item_id == "shimmering_ore" and get_quest_state(QUEST_FINN_SHIMMERING_ORE) == QUEST_STARTED:
        mark_quest_ready_to_turn_in(QUEST_FINN_SHIMMERING_ORE)

func has_item(item_id: String) -> bool:
    return collected_items.get(item_id, 0) > 0

func get_quest_state(quest_id: String) -> String:
    return quest_states.get(quest_id, QUEST_NOT_STARTED)

func is_quest_state(quest_id: String, state: String) -> bool:
    return get_quest_state(quest_id) == state

func set_quest_state(quest_id: String, state: String) -> void:
    if get_quest_state(quest_id) == state:
        return

    quest_states[quest_id] = state
    _refresh_elder_quest_flags()
    quest_changed.emit(quest_id, state)

    if quest_id == QUEST_ELDER_GOLDEN_STAR:
        elder_quest_changed.emit()

func start_quest(quest_id: String) -> void:
    if get_quest_state(quest_id) != QUEST_NOT_STARTED:
        return

    set_quest_state(quest_id, QUEST_STARTED)

func mark_quest_ready_to_turn_in(quest_id: String) -> void:
    var state := get_quest_state(quest_id)
    if state == QUEST_COMPLETED or state == QUEST_LEARNING_CHECK:
        return

    set_quest_state(quest_id, QUEST_READY_TO_TURN_IN)

func start_learning_check(quest_id: String) -> void:
    if get_quest_state(quest_id) == QUEST_COMPLETED:
        return

    set_quest_state(quest_id, QUEST_LEARNING_CHECK)

func complete_quest(quest_id: String) -> void:
    if get_quest_state(quest_id) == QUEST_COMPLETED:
        return

    set_quest_state(quest_id, QUEST_COMPLETED)
    _check_and_grant_tier1_armor()

func award_quest_bonus(quest_id: String) -> void:
    quest_bonuses[quest_id] = true

func has_quest_bonus(quest_id: String) -> bool:
    return quest_bonuses.get(quest_id, false)

func start_elder_quest() -> void:
    start_quest(QUEST_ELDER_GOLDEN_STAR)

func mark_elder_quest_ready_to_turn_in() -> void:
    mark_quest_ready_to_turn_in(QUEST_ELDER_GOLDEN_STAR)

func start_elder_learning_check() -> void:
    start_learning_check(QUEST_ELDER_GOLDEN_STAR)

func complete_elder_quest() -> void:
    if not has_item("golden_star"):
        return

    complete_quest(QUEST_ELDER_GOLDEN_STAR)

func _refresh_elder_quest_flags() -> void:
    var state := get_quest_state(QUEST_ELDER_GOLDEN_STAR)
    elder_quest_started = state != QUEST_NOT_STARTED
    elder_quest_completed = state == QUEST_COMPLETED

func _check_and_grant_tier1_armor() -> void:
    if equipped_armor_tier > 0:
        return

    var required_quests := [QUEST_ELDER_GOLDEN_STAR, QUEST_MIRA_GLOWING_HERB, QUEST_FINN_SHIMMERING_ORE]
    for quest_id in required_quests:
        if get_quest_state(quest_id) != QUEST_COMPLETED:
            return

    equipped_armor_tier = 1
    armor_equipped.emit(1)

func save_game() -> void:
    var data := {
        "selected_profile": selected_profile,
        "player_hp": player_hp,
        "collected_items": collected_items,
        "quest_states": quest_states,
        "quest_bonuses": quest_bonuses,
        "equipped_armor_tier": equipped_armor_tier,
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        return
    file.store_string(JSON.stringify(data))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return

    var data: Variant = JSON.parse_string(file.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        return

    selected_profile = data.get("selected_profile", selected_profile)
    player_hp = data.get("player_hp", player_hp)
    quest_states = data.get("quest_states", quest_states)
    quest_bonuses = data.get("quest_bonuses", quest_bonuses)
    equipped_armor_tier = data.get("equipped_armor_tier", equipped_armor_tier)

    # JSON.parse_string() returns every number as float, and Dictionary values have no
    # static type to auto-coerce them back (unlike equipped_armor_tier's declared int type,
    # which does this implicitly on assignment) - item counts must stay whole numbers.
    var loaded_items: Dictionary = data.get("collected_items", {})
    collected_items = {}
    for item_id in loaded_items.keys():
        collected_items[item_id] = int(loaded_items[item_id])

    _refresh_elder_quest_flags()

func reset_progress() -> void:
    reset_state()
    if get_tree().current_scene != null:
        get_tree().reload_current_scene()

func reset_state() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

    selected_profile = ""
    player_hp = 5
    collected_items = {}
    quest_states = {
        QUEST_ELDER_GOLDEN_STAR: QUEST_NOT_STARTED,
        QUEST_MIRA_GLOWING_HERB: QUEST_NOT_STARTED,
        QUEST_FINN_SHIMMERING_ORE: QUEST_NOT_STARTED,
    }
    quest_bonuses = {}
    equipped_armor_tier = 0
    _refresh_elder_quest_flags()

func _on_profile_changed_autosave(_profile_id: String) -> void:
    save_game()

func _on_quest_changed_autosave(_quest_id: String, _state: String) -> void:
    save_game()

func _on_item_added_autosave(_item_id: String, _amount: int) -> void:
    save_game()

func _on_armor_equipped_autosave(_tier: int) -> void:
    save_game()
