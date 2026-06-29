extends CanvasLayer

@onready var objective_label: Label = $MarginContainer/ObjectiveLabel

func _ready() -> void:
    GameState.item_added.connect(_on_item_added)
    GameState.elder_quest_changed.connect(_on_elder_quest_changed)
    _update_objective()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _update_objective()

func _on_elder_quest_changed() -> void:
    _update_objective()

func _update_objective() -> void:
    if GameState.elder_quest_completed:
        objective_label.text = "Objective complete: The golden star was returned!"
    elif GameState.has_item("golden_star"):
        objective_label.text = "Objective: Return the golden star to Elder Rowan."
    elif GameState.elder_quest_started:
        objective_label.text = "Objective: Find the golden star near the old wall."
    else:
        objective_label.text = "Objective: Talk to Elder Rowan."
