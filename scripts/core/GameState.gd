extends Node

signal item_added(item_id: String, amount: int)
signal elder_quest_changed
signal profile_changed(profile_id: String)
signal quest_changed(quest_id: String, state: String)

const QUEST_ELDER_GOLDEN_STAR := "elder_golden_star"
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
}

var elder_quest_started: bool = false
var elder_quest_completed: bool = false

func set_selected_profile(profile_id: String) -> void:
    selected_profile = profile_id
    profile_changed.emit(profile_id)

func add_item(item_id: String, amount: int = 1) -> void:
    collected_items[item_id] = collected_items.get(item_id, 0) + amount
    item_added.emit(item_id, amount)
    if item_id == "golden_star" and get_quest_state(QUEST_ELDER_GOLDEN_STAR) == QUEST_STARTED:
        mark_elder_quest_ready_to_turn_in()

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

func start_elder_quest() -> void:
    if get_quest_state(QUEST_ELDER_GOLDEN_STAR) != QUEST_NOT_STARTED:
        return
    set_quest_state(QUEST_ELDER_GOLDEN_STAR, QUEST_STARTED)

func mark_elder_quest_ready_to_turn_in() -> void:
    var state := get_quest_state(QUEST_ELDER_GOLDEN_STAR)
    if state == QUEST_COMPLETED or state == QUEST_LEARNING_CHECK:
        return
    set_quest_state(QUEST_ELDER_GOLDEN_STAR, QUEST_READY_TO_TURN_IN)

func start_elder_learning_check() -> void:
    if get_quest_state(QUEST_ELDER_GOLDEN_STAR) == QUEST_COMPLETED:
        return
    set_quest_state(QUEST_ELDER_GOLDEN_STAR, QUEST_LEARNING_CHECK)

func complete_elder_quest() -> void:
    if get_quest_state(QUEST_ELDER_GOLDEN_STAR) == QUEST_COMPLETED or not has_item("golden_star"):
        return
    set_quest_state(QUEST_ELDER_GOLDEN_STAR, QUEST_COMPLETED)

func _refresh_elder_quest_flags() -> void:
    var state := get_quest_state(QUEST_ELDER_GOLDEN_STAR)
    elder_quest_started = state != QUEST_NOT_STARTED
    elder_quest_completed = state == QUEST_COMPLETED
