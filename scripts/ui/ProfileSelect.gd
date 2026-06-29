extends CanvasLayer

func _ready() -> void:
    $PanelContainer/VBoxContainer/MageButton.pressed.connect(_on_mage_pressed)
    $PanelContainer/VBoxContainer/AdventurerButton.pressed.connect(_on_adventurer_pressed)

    # Hide if already selected (just in case)
    if GameState.selected_profile != "":
        queue_free()

func _unhandled_input(event: InputEvent) -> void:
    if GameState.selected_profile != "":
        return

    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_2 or key_event.physical_keycode == KEY_2:
                _on_mage_pressed()
                get_viewport().set_input_as_handled()
            elif key_event.keycode == KEY_5 or key_event.physical_keycode == KEY_5:
                _on_adventurer_pressed()
                get_viewport().set_input_as_handled()

func _on_mage_pressed() -> void:
    GameState.set_selected_profile("grade_2_mage")
    queue_free()

func _on_adventurer_pressed() -> void:
    GameState.set_selected_profile("grade_5_adventurer")
    queue_free()
