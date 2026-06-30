extends CanvasLayer

@onready var objective_label: Label = $MarginContainer/ObjectiveLabel

func _ready() -> void:
    GameState.item_added.connect(_on_item_added)
    GameState.elder_quest_changed.connect(_on_elder_quest_changed)
    GameState.profile_changed.connect(_on_profile_changed)
    GameState.quest_changed.connect(_on_quest_changed)
    _update_objective()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _update_objective()

func _on_elder_quest_changed() -> void:
    _update_objective()

func _on_profile_changed(_profile_id: String) -> void:
    _update_objective()

func _on_quest_changed(_quest_id: String, _state: String) -> void:
    _update_objective()

func _update_objective() -> void:
    var profile := GameState.selected_profile
    if profile == "":
        objective_label.text = "Choose a profile to begin."
        return

    var elder_state := GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR)
    if elder_state != GameState.QUEST_COMPLETED:
        _set_elder_objective(profile, elder_state)
        return

    var mira_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    _set_mira_objective(profile, mira_state)

func _set_elder_objective(profile: String, quest_state: String) -> void:
    if profile == "grade_2_mage":
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Mage task: Bring the golden star back to Elder Rowan."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Mage task: Find the golden star near the wall."
        else:
            objective_label.text = "Mage task: Talk to Elder Rowan."
    elif profile == "grade_5_adventurer":
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Adventurer task: Return the recovered golden star to Elder Rowan."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Adventurer task: Retrieve the golden star near the old wall and report back."
        else:
            objective_label.text = "Adventurer task: Report to Elder Rowan."

func _set_mira_objective(profile: String, quest_state: String) -> void:
    if profile == "grade_2_mage":
        if quest_state == GameState.QUEST_COMPLETED:
            objective_label.text = "Mage garden task complete: Glowing herb returned!"
        elif quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Mage garden task: Bring the glowing herb back to Mira."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Mage garden task: Find the glowing herb."
        else:
            objective_label.text = "Mage garden task: Talk to Mira the Gardener."
    elif profile == "grade_5_adventurer":
        if quest_state == GameState.QUEST_COMPLETED:
            objective_label.text = "Adventurer garden task complete: Garden restored."
        elif quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Adventurer garden task: Return the glowing herb to Mira."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Adventurer garden task: Gather the glowing herb for Mira."
        else:
            objective_label.text = "Adventurer garden task: Speak with Mira the Gardener."
