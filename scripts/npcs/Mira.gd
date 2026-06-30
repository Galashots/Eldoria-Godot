extends StaticBody2D

signal dialogue_requested(speaker_name: String, line: String)
signal learning_check_requested(speaker_name: String, question: String, choices: Array, correct_answer: String, quest_id: String, completion_line: String)

@export var display_name: String = "Mira the Gardener"

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
    var quest_state := GameState.get_quest_state(GameState.QUEST_MIRA_GLOWING_HERB)
    var line: String

    if quest_state == GameState.QUEST_COMPLETED:
        line = "The garden glows again. Thank you!"
    elif quest_state == GameState.QUEST_READY_TO_TURN_IN or quest_state == GameState.QUEST_LEARNING_CHECK:
        _request_learning_check()
        return
    elif GameState.has_item("glowing_herb"):
        GameState.mark_quest_ready_to_turn_in(GameState.QUEST_MIRA_GLOWING_HERB)
        _request_learning_check()
        return
    else:
        GameState.start_quest(GameState.QUEST_MIRA_GLOWING_HERB)
        line = _get_offer_line()

    dialogue_requested.emit(display_name, line)

func _get_offer_line() -> String:
    if GameState.selected_profile == "grade_2_mage":
        return "Young mage, can you find a glowing herb for my garden?"
    if GameState.selected_profile == "grade_5_adventurer":
        return "Adventurer, gather a glowing herb so we can restore the village garden."
    return "Can you find a glowing herb for my garden?"

func _request_learning_check() -> void:
    if GameState.selected_profile == "grade_2_mage":
        learning_check_requested.emit(display_name, "What word rhymes with star?", ["car", "tree"], "car", GameState.QUEST_MIRA_GLOWING_HERB, "The garden glows again. Thank you!")
    elif GameState.selected_profile == "grade_5_adventurer":
        learning_check_requested.emit(display_name, "Which sentence uses a stronger verb?", ["The hero went fast.", "The hero sprinted."], "The hero sprinted.", GameState.QUEST_MIRA_GLOWING_HERB, "The garden glows again. Thank you!")
    else:
        GameState.complete_quest(GameState.QUEST_MIRA_GLOWING_HERB)
        dialogue_requested.emit(display_name, "The garden glows again. Thank you!")

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
