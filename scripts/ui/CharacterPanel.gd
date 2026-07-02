extends CanvasLayer

@onready var profile_label: Label = $PanelContainer/VBoxContainer/ProfileLabel
@onready var quest_label: Label = $PanelContainer/VBoxContainer/QuestLabel
@onready var items_label: Label = $PanelContainer/VBoxContainer/ItemsLabel
@onready var bonuses_label: Label = $PanelContainer/VBoxContainer/BonusesLabel
@onready var equipment_label: Label = $PanelContainer/VBoxContainer/EquipmentLabel
@onready var coins_label: Label = $PanelContainer/VBoxContainer/CoinsLabel
@onready var weapons_list: VBoxContainer = $PanelContainer/VBoxContainer/WeaponsList
@onready var pets_list: VBoxContainer = $PanelContainer/VBoxContainer/PetsList
@onready var reset_button: Button = $PanelContainer/VBoxContainer/ResetButton
@onready var confirm_reset_container: VBoxContainer = $PanelContainer/VBoxContainer/ConfirmResetContainer
@onready var cancel_reset_button: Button = $PanelContainer/VBoxContainer/ConfirmResetContainer/CancelResetButton
@onready var confirm_reset_button: Button = $PanelContainer/VBoxContainer/ConfirmResetContainer/ConfirmResetButton

func _ready() -> void:
    visible = false
    confirm_reset_container.visible = false
    GameState.profile_changed.connect(_on_profile_changed)
    GameState.item_added.connect(_on_item_added)
    GameState.quest_changed.connect(_on_quest_changed)
    GameState.armor_equipped.connect(_on_armor_equipped)
    GameState.coins_changed.connect(_on_coins_changed)
    GameState.gear_changed.connect(_on_gear_changed)
    GameState.pet_changed.connect(_on_pet_changed)
    reset_button.pressed.connect(_on_reset_pressed)
    cancel_reset_button.pressed.connect(_on_reset_cancelled)
    confirm_reset_button.pressed.connect(_on_reset_confirmed)
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
        else:
            confirm_reset_container.visible = false
        get_viewport().set_input_as_handled()

func _on_reset_pressed() -> void:
    confirm_reset_container.visible = true

func _on_reset_cancelled() -> void:
    confirm_reset_container.visible = false

func _on_reset_confirmed() -> void:
    GameState.reset_progress()

func _on_profile_changed(_profile_id: String) -> void:
    _refresh()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _refresh()

func _on_quest_changed(_quest_id: String, _state: String) -> void:
    _refresh()

func _on_armor_equipped(_tier: int) -> void:
    _refresh()

func _on_coins_changed(_coins: int) -> void:
    _refresh()

func _on_gear_changed() -> void:
    _refresh()

func _on_pet_changed() -> void:
    _refresh()

func _refresh() -> void:
    profile_label.text = "Profile: " + ContentDefinitions.get_profile_label(GameState.selected_profile)
    quest_label.text = "Current quest: " + _get_current_quest_summary()
    items_label.text = "Items: " + _get_items_summary()
    bonuses_label.text = "Bonuses earned: " + _get_bonuses_summary()
    equipment_label.text = "Equipment: " + _get_equipment_summary()
    coins_label.text = "Coins: %d" % GameState.coins
    _refresh_weapons_list()
    _refresh_pets_list()

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
        GameState.QUEST_YARROW_SILVERLEAF,
    ]
    var badges: Array[String] = []
    for quest_id in quest_ids:
        if GameState.has_quest_bonus(quest_id):
            badges.append(ContentDefinitions.get_badge_label(quest_id))

    if badges.is_empty():
        return "none yet"
    return ", ".join(badges)

func _get_equipment_summary() -> String:
    var parts: Array[String] = []
    if GameState.equipped_armor_tier > 0:
        parts.append(ContentDefinitions.get_armor_tier_label(GameState.equipped_armor_tier))
    if GameState.equipped_weapon != "":
        parts.append(ContentDefinitions.get_gear_label(GameState.equipped_weapon))
    if GameState.equipped_pet != "":
        parts.append(ContentDefinitions.get_pet_label(GameState.equipped_pet))

    if parts.is_empty():
        return "none yet"
    return ", ".join(parts)

func _refresh_weapons_list() -> void:
    for child in weapons_list.get_children():
        child.queue_free()

    for gear_id in GameState.owned_gear:
        var row := HBoxContainer.new()

        var label := Label.new()
        label.text = ContentDefinitions.get_gear_label(gear_id)
        label.custom_minimum_size = Vector2(160, 0)
        row.add_child(label)

        var button := Button.new()
        if GameState.equipped_weapon == gear_id:
            button.text = "Equipped"
            button.disabled = true
        else:
            button.text = "Equip"
            button.pressed.connect(GameState.equip_weapon.bind(gear_id))
        row.add_child(button)

        weapons_list.add_child(row)

func _refresh_pets_list() -> void:
    for child in pets_list.get_children():
        child.queue_free()

    for pet_id in GameState.owned_pets:
        var pet := ContentDefinitions.get_pet(pet_id)
        if pet == null:
            continue

        var row := HBoxContainer.new()

        var label := Label.new()
        label.text = "%s (%s) +%d Max HP" % [pet.label, pet.rarity, pet.hp_bonus]
        label.custom_minimum_size = Vector2(220, 0)
        label.add_theme_color_override("font_color", ContentDefinitions.get_rarity_color(pet.rarity))
        row.add_child(label)

        var button := Button.new()
        if GameState.equipped_pet == pet_id:
            button.text = "Unequip"
            button.pressed.connect(GameState.equip_pet.bind(""))
        else:
            button.text = "Equip"
            button.pressed.connect(GameState.equip_pet.bind(pet_id))
        row.add_child(button)

        pets_list.add_child(row)

func _get_current_quest_summary() -> String:
    var elder_state := GameState.get_quest_state(GameState.QUEST_ELDER_GOLDEN_STAR)
    if elder_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_ELDER_GOLDEN_STAR, elder_state)

    var mira_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    if mira_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_MIRA_GLOWING_HERB, mira_state)

    var finn_state := GameState.get_quest_state(GameState.QUEST_FINN_SHIMMERING_ORE)
    if finn_state != GameState.QUEST_COMPLETED:
        return ContentDefinitions.get_quest_summary(GameState.QUEST_FINN_SHIMMERING_ORE, finn_state)

    var yarrow_state := GameState.get_quest_state(GameState.QUEST_YARROW_SILVERLEAF)
    return ContentDefinitions.get_quest_summary(GameState.QUEST_YARROW_SILVERLEAF, yarrow_state)
