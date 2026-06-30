extends CanvasLayer

@onready var profile_label: Label = $PanelContainer/VBoxContainer/ProfileLabel
@onready var quest_label: Label = $PanelContainer/VBoxContainer/QuestLabel
@onready var items_label: Label = $PanelContainer/VBoxContainer/ItemsLabel
@onready var equipment_label: Label = $PanelContainer/VBoxContainer/EquipmentLabel

func _ready() -> void:
    visible = false
    GameState.profile_changed.connect(_on_profile_changed)
    GameState.item_added.connect(_on_item_added)
    GameState.quest_changed.connect(_on_quest_changed)
    _refresh()

func _unhandled_input(event: InputEvent) -> void:
    if GameState.selected_profile == "":
        return
    if not event is InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    if key_event.keycode == KEY_C or key_event.physical_keycode == KEY_C or key_event.keycode == KEY_I or key_event.physical_keycode == KEY_I:
        visible = not visible
        if visible:
            _refresh()
        get_viewport().set_input_as_handled()

func _on_profile_changed(_profile_id: String) -> void:
    _refresh()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _refresh()

func _on_quest_changed(_quest_id: String, _state: String) -> void:
    _refresh()

func _refresh() -> void:
    profile_label.text = "Profile: " + _get_profile_label()
    quest_label.text = "Current quest: " + _get_current_quest_summary()
    items_label.text = "Items: " + _get_items_summary()
    equipment_label.text = "Equipment: coming soon"

func _get_profile_label() -> String:
    if GameState.selected_profile == "grade_2_mage":
        return "Grade 2 Mage"
    if GameState.selected_profile == "grade_5_adventurer":
        return "Grade 5 Adventurer"
    return "None selected"

func _get_items_summary() -> String:
    var items: Array[String] = []
    if GameState.has_item("golden_star"):
        items.append("Golden Star")
    if GameState.has_item("glowing_herb"):
        items.append("Glowing Herb")

    if items.is_empty():
        return "none yet"
    return ", ".join(items)

func _get_current_quest_summary() -> String:
    var elder_state := GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR)
    if elder_state != GameState.QUEST_COMPLETED:
        return _describe_elder_quest(elder_state)

    var mira_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    return _describe_mira_quest(mira_state)

func _describe_elder_quest(state: String) -> String:
    if state == GameState.QUEST_NOT_STARTED:
        return "Talk to Elder Rowan"
    if state == GameState.QUEST_STARTED:
        return "Find the golden star"
    if state == GameState.QUEST_READY_TO_TURN_IN:
        return "Return the golden star to Elder Rowan"
    if state == GameState.QUEST_LEARNING_CHECK:
        return "Answer Elder Rowan's question"
    return "Elder Rowan quest complete"

func _describe_mira_quest(state: String) -> String:
    if state == GameState.QUEST_NOT_STARTED:
        return "Talk to Mira the Gardener"
    if state == GameState.QUEST_STARTED:
        return "Find the glowing herb"
    if state == GameState.QUEST_READY_TO_TURN_IN:
        return "Return the glowing herb to Mira"
    if state == GameState.QUEST_LEARNING_CHECK:
        return "Answer Mira's question"
    return "Mira's garden quest complete"
