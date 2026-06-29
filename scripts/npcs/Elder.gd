extends StaticBody2D

signal dialogue_requested(speaker_name: String, line: String)
signal learning_check_requested(speaker_name: String, question: String, choices: Array, correct_answer: String)

@export var display_name: String = "Elder Rowan"

@onready var interaction_prompt: Label = $InteractionPrompt

var player_nearby: bool = false

func _ready() -> void:
    $InteractionArea.body_entered.connect(_on_body_entered)
    $InteractionArea.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
    if GameState.selected_profile == "":
        return
    if not player_nearby or not event is InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    if key_event.keycode != KEY_E and key_event.physical_keycode != KEY_E:
        return

    _interact()
    get_viewport().set_input_as_handled()

func _interact() -> void:
    var line: String

    if GameState.elder_quest_completed:
        line = "Thank you again. Eldoria shines brighter today."
    elif GameState.has_item("golden_star"):
        _request_learning_check()
        return
    else:
        GameState.start_elder_quest()
        if GameState.selected_profile == "grade_2_mage":
            line = "Young mage, can you find the golden star near the wall?"
        elif GameState.selected_profile == "grade_5_adventurer":
            line = "Adventurer, recover the golden star near the old wall and return with your findings."
        else:
            line = "Please find the golden star near the old wall."

    dialogue_requested.emit(display_name, line)

func _request_learning_check() -> void:
    if GameState.selected_profile == "grade_2_mage":
        learning_check_requested.emit(display_name, "Which number is bigger?", ["7", "4"], "7")
    elif GameState.selected_profile == "grade_5_adventurer":
        learning_check_requested.emit(display_name, "What is 6 x 7?", ["42", "36"], "42")
    else:
        GameState.complete_elder_quest()
        dialogue_requested.emit(display_name, "You found it! The village is grateful.")

func _on_body_entered(body: Node2D) -> void:
    if GameState.selected_profile == "":
        return
    if body is CharacterBody2D:
        player_nearby = true
        interaction_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
    if body is CharacterBody2D:
        player_nearby = false
        interaction_prompt.visible = false
