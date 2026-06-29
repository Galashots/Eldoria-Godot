extends Node

signal item_added(item_id: String, amount: int)

var selected_profile: String = ""
var player_hp: int = 5
var collected_items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
    collected_items[item_id] = collected_items.get(item_id, 0) + amount
    item_added.emit(item_id, amount)

func has_item(item_id: String) -> bool:
    return collected_items.get(item_id, 0) > 0
