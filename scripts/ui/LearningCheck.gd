extends CanvasLayer

signal dialogue_requested(speaker_name: String, line: String)

@onready var question_label: Label = $PanelContainer/VBoxContainer/QuestionLabel
@onready var feedback_label: Label = $PanelContainer/VBoxContainer/FeedbackLabel
@onready var first_button: Button = $PanelContainer/VBoxContainer/FirstAnswerButton
@onready var second_button: Button = $PanelContainer/VBoxContainer/SecondAnswerButton

var _speaker_name: String = "Elder Rowan"
var _correct_answer: String = ""
var _choices: Array = []
var _quest_id: String = "elder_golden_star"
var _completion_line: String = "You found it! The village is grateful."

func _ready() -> void:
    visible = false
    first_button.pressed.connect(_on_first_answer_pressed)
    second_button.pressed.connect(_on_second_answer_pressed)

func show_check(speaker_name: String, question: String, choices: Array, correct_answer: String, quest_id: String = "elder_golden_star", completion_line: String = "You found it! The village is grateful.") -> void:
    GameState.start_learning_check(quest_id)
    _speaker_name = speaker_name
    _choices = choices
    _correct_answer = correct_answer
    _quest_id = quest_id
    _completion_line = completion_line
    question_label.text = question
    feedback_label.text = "Choose an answer."
    first_button.text = str(choices[0])
    second_button.text = str(choices[1])
    visible = true

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if not event is InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    if key_event.keycode == KEY_1 or key_event.physical_keycode == KEY_1:
        _select_answer(0)
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_2 or key_event.physical_keycode == KEY_2:
        _select_answer(1)
        get_viewport().set_input_as_handled()

func _on_first_answer_pressed() -> void:
    _select_answer(0)

func _on_second_answer_pressed() -> void:
    _select_answer(1)

func _select_answer(index: int) -> void:
    if index < 0 or index >= _choices.size():
        return

    var selected_answer := str(_choices[index])
    var line := _completion_line
    if selected_answer == _correct_answer:
        GameState.award_quest_bonus(_quest_id)
        line = "%s Bonus earned! You've received the %s." % [_completion_line, ContentDefinitions.get_badge_label(_quest_id)]

    GameState.complete_quest(_quest_id)
    visible = false
    dialogue_requested.emit(_speaker_name, line)
