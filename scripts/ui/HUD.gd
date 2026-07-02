extends CanvasLayer

@onready var objective_label: Label = $MarginContainer/ObjectiveLabel
@onready var hp_label: Label = $CombatMarginContainer/CombatVBox/HPLabel
@onready var coins_label: Label = $CombatMarginContainer/CombatVBox/CoinsLabel
@onready var streak_label: Label = $CombatMarginContainer/CombatVBox/StreakLabel

func _ready() -> void:
    GameState.item_added.connect(_on_item_added)
    GameState.elder_quest_changed.connect(_on_elder_quest_changed)
    GameState.profile_changed.connect(_on_profile_changed)
    GameState.quest_changed.connect(_on_quest_changed)
    GameState.player_damaged.connect(_on_player_damaged)
    GameState.combat_streak_changed.connect(_on_combat_streak_changed)
    GameState.coins_changed.connect(_on_coins_changed)
    _update_objective()
    _update_hp_label(GameState.player_hp, GameState.get_effective_max_hp())
    _update_coins_label(GameState.coins)
    _update_streak_label(GameState.combat_streak, GameState.get_combat_multiplier())

func _on_player_damaged(current_hp: int, max_hp: int) -> void:
    _update_hp_label(current_hp, max_hp)

func _on_coins_changed(coins: int) -> void:
    _update_coins_label(coins)

func _update_coins_label(coins: int) -> void:
    coins_label.text = "Coins: %d" % coins

func _update_hp_label(current_hp: int, max_hp: int) -> void:
    hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

func _on_combat_streak_changed(streak: int, multiplier: float) -> void:
    _update_streak_label(streak, multiplier)

func _update_streak_label(streak: int, multiplier: float) -> void:
    if streak <= 0:
        streak_label.text = ""
    else:
        streak_label.text = "On Fire! x%s" % String.num(multiplier, 1)

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
    if mira_state != GameState.QUEST_COMPLETED:
        _set_mira_objective(profile, mira_state)
        return

    var finn_state := GameState.get_quest_state(GameState.QUEST_FINN_SHIMMERING_ORE)
    if finn_state != GameState.QUEST_COMPLETED:
        _set_finn_objective(profile, finn_state)
        return

    var yarrow_state := GameState.get_quest_state(GameState.QUEST_YARROW_SILVERLEAF)
    _set_yarrow_objective(profile, yarrow_state)

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
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Mage garden task: Bring the glowing herb back to Mira."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Mage garden task: Find the glowing herb."
        else:
            objective_label.text = "Mage garden task: Talk to Mira the Gardener."
    elif profile == "grade_5_adventurer":
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Adventurer garden task: Return the glowing herb to Mira."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Adventurer garden task: Gather the glowing herb for Mira."
        else:
            objective_label.text = "Adventurer garden task: Speak with Mira the Gardener."

func _set_finn_objective(profile: String, quest_state: String) -> void:
    if profile == "grade_2_mage":
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Mage forge task: Bring the shimmering ore back to Finn."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Mage forge task: Find the shimmering ore."
        else:
            objective_label.text = "Mage forge task: Talk to Finn the Blacksmith."
    elif profile == "grade_5_adventurer":
        if quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Adventurer forge task: Return the shimmering ore to Finn."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Adventurer forge task: Recover shimmering ore for Finn's forge."
        else:
            objective_label.text = "Adventurer forge task: Speak with Finn the Blacksmith."

func _set_yarrow_objective(profile: String, quest_state: String) -> void:
    if profile == "grade_2_mage":
        if quest_state == GameState.QUEST_COMPLETED:
            objective_label.text = "Mage remedy task complete: The village breathes easier!"
        elif quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Mage remedy task: Bring silverleaf back to Yarrow."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Mage remedy task: Find silverleaf."
        else:
            objective_label.text = "Mage remedy task: Talk to Yarrow the Healer."
    elif profile == "grade_5_adventurer":
        if quest_state == GameState.QUEST_COMPLETED:
            objective_label.text = "Adventurer remedy task complete: Yarrow's cure is brewed."
        elif quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
            objective_label.text = "Adventurer remedy task: Return silverleaf to Yarrow."
        elif quest_state == GameState.QUEST_STARTED:
            objective_label.text = "Adventurer remedy task: Gather silverleaf for Yarrow's cure."
        else:
            objective_label.text = "Adventurer remedy task: Speak with Yarrow the Healer."
