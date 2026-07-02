extends CanvasLayer

## The M3 gear vendor panel. Gear rows are built once from ContentDefinitions.GEAR_DEFINITIONS
## rather than hardcoded in the scene, so adding a new .tres weapon needs no scene edit.

@onready var coins_label: Label = $PanelContainer/VBoxContainer/CoinsLabel
@onready var gear_list: VBoxContainer = $PanelContainer/VBoxContainer/GearList
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

var _buy_buttons: Dictionary = {}

func _ready() -> void:
    visible = false
    GameState.coins_changed.connect(_on_state_changed)
    GameState.gear_changed.connect(_on_state_changed)
    close_button.pressed.connect(_on_close_pressed)
    _build_gear_rows()
    _refresh()

func open_shop() -> void:
    visible = true
    _refresh()

func _on_close_pressed() -> void:
    visible = false

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
    GameState.buy_gear(gear_id)

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
