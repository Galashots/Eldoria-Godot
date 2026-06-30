extends CanvasLayer

@onready var profile_label: Label = $PanelContainer/VBoxContainer/ProfileLabel
@onready var quest_label: Label = $PanelContainer/VBoxContainer/QuestLabel
@onready var items_label: Label = $PanelContainer/VBoxContainer/ItemsLabel
@onready var bonuses_label: Label = $PanelContainer/VBoxContainer/BonusesLabel
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
    profile_label.text = "Profile: " + ContentDefinitions.get_profile_label(GameState.selected_profile)
    quest_label.text = "Current quest: " + _get_current_quest_summary()
    items_label.text = "Items: " + _get_items_summary()
    bonuses_label.text = "Bonuses earned: " + _get_bonuses_summary()
    equipment_label.text = "Equipment: coming soon"

func _get_items_summary() -> String:
    var items: Array[String] = []
    if GameState.has_item("golden_star"):
        items.append(ContentDefinitions.get_item_label("golden_star"))
    if GameState.has_item("glowing_herb"):
        items.append(ContentDefinitions.get_item_label("glowing_herb"))
    if GameState.has_item("shimmering_ore"):
        items.append(ContentDefinitions.get_item_label("shimmering_ore"))

    if items.is_empty():
        return "none yet"
    return ", ".join(items)

func _get_bonuses_summary() -> String:
    var quest_ids: Array[String] = [
        GameState.QUEST_ELDER_GOLDEN_STAR,
        GameState.QUEST_MIRA_GLOWING_HERB,
        GameState.QUEST_FINN_SHIMMERING_ORE,
    ]
    var earned := 0
    for quest_id in quest_ids:
        if GameState.has_quest_bonus(quest_id):
            earned += 1
    return "%d/%d" % [earned, quest_ids.size()]

func _get_current_quest_summary() -> String:
    var elder_state := GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR)
    if elder_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_ELDER_GOLDEN_STAR, elder_state)

    var mira_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    if mira_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_MIRA_GLOWING_HERB, mira_state)

    var finn_state := GameState.get_quest_state(GameState.QUEST_FINN_SHIMMERING_ORE)
    return ContentDefinitions.get_quest_summary(GameState.QUEST_FINN_SHIMMERING_ORE, finn_state)
