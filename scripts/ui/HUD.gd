extends CanvasLayer

@onready var objective_label: Label = $MarginContainer/ObjectiveLabel

func _ready() -> void:
    GameState.item_added.connect(_on_item_added)
    GameState.elder_quest_changed.connect(_on_elder_quest_changed)
    GameState.profile_changed.connect(_on_profile_changed)
    _update_objective()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _update_objective()

func _on_elder_quest_changed() -> void:
    _update_objective()

func _on_profile_changed(_profile_id: String) -> void:
    _update_objective()

func _update_objective() -> void:
    var profile := GameState.selected_profile
    if profile == "":
        objective_label.text = "Choose a profile to begin."
        return

    if profile == "grade_2_mage":
        if GameState.elder_quest_completed:
            objective_label.text = "Mage task complete: Golden star returned!"
        elif GameState.has_item("golden_star"):
            objective_label.text = "Mage task: Bring the golden star back to Elder Rowan."
        elif GameState.elder_quest_started:
            objective_label.text = "Mage task: Find the golden star near the wall."
        else:
            objective_label.text = "Mage task: Talk to Elder Rowan."
    elif profile == "grade_5_adventurer":
        if GameState.elder_quest_completed:
            objective_label.text = "Adventurer task complete: Golden star recovered and reported."
        elif GameState.has_item("golden_star"):
            objective_label.text = "Adventurer task: Return the recovered golden star to Elder Rowan."
        elif GameState.elder_quest_started:
            objective_label.text = "Adventurer task: Retrieve the golden star near the old wall and report back."
        else:
            objective_label.text = "Adventurer task: Report to Elder Rowan."
