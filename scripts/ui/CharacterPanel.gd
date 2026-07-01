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
    GameState.armor_equipped.connect(_on_armor_equipped)
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

func _on_armor_equipped(_tier: int) -> void:
    _refresh()

func _refresh() -> void:
    profile_label.text = "Profile: " + ContentDefinitions.get_profile_label(GameState.selected_profile)
    quest_label.text = "Current quest: " + _get_current_quest_summary()
    items_label.text = "Items: " + _get_items_summary()
    bonuses_label.text = "Bonuses earned: " + _get_bonuses_summary()
    equipment_label.text = "Equipment: " + _get_equipment_summary()

func _get_items_summary() -> String:
    var items: Array[String] = []
    for item_id in GameState.collected_items.keys():
        var count: int = GameState.collected_items[item_id]
        if count <= 0:
            continue
        var label := ContentDefinitions.get_item_label(item_id)
        if count > 1:
            label = "%s x%d" % [label, count]
        items.append(label)

    if items.is_empty():
        return "none yet"
    return ", ".join(items)

func _get_bonuses_summary() -> String:
    var quest_ids: Array[String] = [
        GameState.QUEST_ELDER_GOLDEN_STAR,
        GameState.QUEST_MIRA_GLOWING_HERB,
        GameState.QUEST_FINN_SHIMMERING_ORE,
    ]
    var badges: Array[String] = []
    for quest_id in quest_ids:
        if GameState.has_quest_bonus(quest_id):
            badges.append(ContentDefinitions.get_badge_label(quest_id))

    if badges.is_empty():
        return "none yet"
    return ", ".join(badges)

func _get_equipment_summary() -> String:
    if GameState.equipped_armor_tier <= 0:
        return "none yet"
    return ContentDefinitions.get_armor_tier_label(GameState.equipped_armor_tier)

func _get_current_quest_summary() -> String:
    var elder_state := GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR)
    if elder_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_ELDER_GOLDEN_STAR, elder_state)

    var mira_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    if mira_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_MIRA_GLOWING_HERB, mira_state)

    var finn_state := GameState.get_quest_state(GameState.QUEST_FINN_SHIMMERING_ORE)
    return ContentDefinitions.get_quest_summary(GameState.QUEST_FINN_SHIMMERING_ORE, finn_state)
