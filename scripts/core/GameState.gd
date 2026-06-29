extends Node

signal item_added(item_id: String, amount: int)
signal elder_quest_changed

var selected_profile: String = ""
var player_hp: int = 5
var collected_items: Dictionary = {}
var elder_quest_started: bool = false
var elder_quest_completed: bool = false

func add_item(item_id: String, amount: int = 1) -> void:
    collected_items[item_id] = collected_items.get(item_id, 0) + amount
    item_added.emit(item_id, amount)

func has_item(item_id: String) -> bool:
    return collected_items.get(item_id, 0) > 0

func start_elder_quest() -> void:
    if elder_quest_started:
        return

    elder_quest_started = true
    elder_quest_changed.emit()

func complete_elder_quest() -> void:
    if elder_quest_completed or not has_item("golden_star"):
        return

    elder_quest_started = true
    elder_quest_completed = true
    elder_quest_changed.emit()
