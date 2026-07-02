extends CanvasLayer

## The M3 gear vendor panel. Gear rows are built once from ContentDefinitions.GEAR_DEFINITIONS
## rather than hardcoded in the scene, so adding a new .tres weapon needs no scene edit.
##
## After a successful purchase, an optional bonus-only "count out the coins" beat
## (CoinCountPanel) offers stealth numeracy practice per docs/design/EXPANSION_BACKLOG.md's
## "Count-out-the-coins at the Merchant" slice: Grade 2 picks coins that sum to the price,
## Grade 5 must also use the fewest coins. The purchase has ALREADY completed before this
## panel appears, so skipping or answering wrong never blocks or undoes anything - correct
## counting only ever adds one bonus coin on top (docs/design/RESEARCH_NOTES.md §9.2).

const CoinCounting := preload("res://scripts/core/CoinCounting.gd")

@onready var shop_panel: PanelContainer = $PanelContainer
@onready var coins_label: Label = $PanelContainer/VBoxContainer/CoinsLabel
@onready var gear_list: VBoxContainer = $PanelContainer/VBoxContainer/GearList
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

@onready var coin_count_panel: PanelContainer = $CoinCountPanel
@onready var coin_count_prompt_label: Label = $CoinCountPanel/VBoxContainer/PromptLabel
@onready var coin_count_total_label: Label = $CoinCountPanel/VBoxContainer/TotalLabel
@onready var coin_buttons_row: HBoxContainer = $CoinCountPanel/VBoxContainer/CoinButtons
@onready var coin_count_reset_button: Button = $CoinCountPanel/VBoxContainer/ResetButton
@onready var coin_count_confirm_button: Button = $CoinCountPanel/VBoxContainer/ConfirmButton
@onready var coin_count_skip_button: Button = $CoinCountPanel/VBoxContainer/SkipButton
@onready var coin_count_feedback_label: Label = $CoinCountPanel/VBoxContainer/FeedbackLabel

var _buy_buttons: Dictionary = {}
var _coin_count_price: int = 0
var _chosen_coins: Array[int] = []

func _ready() -> void:
    visible = false
    GameState.coins_changed.connect(_on_state_changed)
    GameState.gear_changed.connect(_on_state_changed)
    close_button.pressed.connect(_on_close_pressed)
    coin_count_reset_button.pressed.connect(_on_coin_count_reset_pressed)
    coin_count_confirm_button.pressed.connect(_on_coin_count_confirm_pressed)
    coin_count_skip_button.pressed.connect(_on_coin_count_skip_pressed)
    _build_gear_rows()
    _build_coin_buttons()
    coin_count_panel.visible = false
    _refresh()

func open_shop() -> void:
    visible = true
    shop_panel.visible = true
    coin_count_panel.visible = false
    _refresh()

func _on_close_pressed() -> void:
    visible = false
    coin_count_panel.visible = false

func _build_gear_rows() -> void:
    for gear in ContentDefinitions.GEAR_DEFINITIONS:
        var row := HBoxContainer.new()

        var label := Label.new()
        label.text = "%s (%s) +%d dmg" % [gear.label, gear.rarity, gear.damage_bonus]
        label.add_theme_color_override("font_color", ContentDefinitions.get_rarity_color(gear.rarity))
        label.custom_minimum_size = Vector2(220, 0)
        row.add_child(label)

        var button := Button.new()
        button.pressed.connect(_on_buy_pressed.bind(gear.id))
        row.add_child(button)

        gear_list.add_child(row)
        _buy_buttons[gear.id] = button

func _on_buy_pressed(gear_id: String) -> void:
    AudioManager.play_sfx("ui_click")
    var gear := ContentDefinitions.get_gear(gear_id)
    if not GameState.buy_gear(gear_id) or gear == null:
        return

    _open_coin_count_beat(gear.price)

func _on_state_changed(_value = null) -> void:
    _refresh()

func _refresh() -> void:
    coins_label.text = "Coins: %d" % GameState.coins

    for gear in ContentDefinitions.GEAR_DEFINITIONS:
        var button: Button = _buy_buttons[gear.id]
        if GameState.owns_gear(gear.id):
            button.text = "Owned"
            button.disabled = true
        else:
            button.text = "Buy (%d)" % gear.price
            button.disabled = gear.price > GameState.coins

## --- Bonus-only coin-counting beat ---------------------------------------------------------

func _build_coin_buttons() -> void:
    for denomination in CoinCounting.DENOMINATIONS:
        var button := Button.new()
        button.text = str(denomination)
        button.pressed.connect(_on_coin_button_pressed.bind(denomination))
        coin_buttons_row.add_child(button)

func _open_coin_count_beat(price: int) -> void:
    _coin_count_price = price
    _chosen_coins = []
    coin_count_prompt_label.text = _get_prompt_text(price)
    coin_count_feedback_label.text = ""
    _update_coin_count_total_label()
    # The two panels share the same screen rect; showing both at once bleeds the shop text
    # through the counting panel, so the shop hides while the beat is up.
    shop_panel.visible = false
    coin_count_panel.visible = true

func _get_prompt_text(price: int) -> String:
    if GameState.selected_profile == "grade_2_mage":
        return "The weapon costs %d coins. Pick coins that add up to %d!" % [price, price]
    if GameState.selected_profile == "grade_5_adventurer":
        return "The weapon costs %d coins. Pick coins that add up to %d, using the fewest coins you can!" % [price, price]
    return "Pick coins that add up to %d." % price

func _on_coin_button_pressed(denomination: int) -> void:
    AudioManager.play_sfx("ui_click")
    _chosen_coins.append(denomination)
    _update_coin_count_total_label()

func _on_coin_count_reset_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _chosen_coins = []
    coin_count_feedback_label.text = ""
    _update_coin_count_total_label()

func _update_coin_count_total_label() -> void:
    var total := 0
    for coin in _chosen_coins:
        total += coin
    coin_count_total_label.text = "Your coins: %d" % total

func _on_coin_count_confirm_pressed() -> void:
    AudioManager.play_sfx("ui_click")

    var is_correct: bool
    if GameState.selected_profile == "grade_5_adventurer":
        is_correct = CoinCounting.is_fewest_coins(_chosen_coins, _coin_count_price)
    else:
        is_correct = CoinCounting.sum_matches_price(_chosen_coins, _coin_count_price)

    if is_correct:
        GameState.add_coins(1)
        AudioManager.play_sfx("coin_chime")
        coin_count_feedback_label.text = "Exactly right! Bonus coin earned!"
    else:
        coin_count_feedback_label.text = "Good try! Here's your weapon anyway."

    await get_tree().create_timer(1.2).timeout
    coin_count_panel.visible = false
    shop_panel.visible = visible

func _on_coin_count_skip_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    coin_count_panel.visible = false
    shop_panel.visible = visible
