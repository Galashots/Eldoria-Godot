class_name ComprehensionCheck
extends CanvasLayer

## Elder's "what did you notice?" bonus-only reading-comprehension check. Deliberately a light
## sibling of LearningCheck rather than a reuse of it: LearningCheck is tightly coupled to a
## quest_id (start_learning_check/complete_quest/award_quest_bonus), but this check has zero
## quest coupling - it can fire any time an eligible codex/keepsake entry exists, independent
## of quest state - so it follows CombatQuestion.gd's "separate on purpose" precedent instead.
## Strictly bonus-only per docs/design/NORTH_STAR.md: any answer (or no answer at all, since
## the child can just walk away) is fine - a correct answer awards a small bonus badge via
## GameState.award_comprehension_bonus(); a wrong answer gets a warm, encouraging line and
## nothing is ever lost.

signal dialogue_requested(speaker_name: String, line: String)

const CORRECT_LINE_SUFFIX := " Bonus earned! You've received the %s." % ContentDefinitions.COMPREHENSION_BADGE_LABEL
const WRONG_LINE := "Not quite, but thank you for sharing what you noticed!"

@onready var question_label: Label = $PanelContainer/VBoxContainer/QuestionLabel
@onready var first_button: Button = $PanelContainer/VBoxContainer/FirstAnswerButton
@onready var second_button: Button = $PanelContainer/VBoxContainer/SecondAnswerButton

var _speaker_name: String = "Elder Rowan"
var _entry_id: String = ""
var _correct_answer: String = ""
var _choices: Array = []

func _ready() -> void:
    visible = false
    first_button.pressed.connect(_on_first_answer_pressed)
    second_button.pressed.connect(_on_second_answer_pressed)

## Pure logic: picks the first eligible entry_id (a codex creature or keepsake the child has
## actually unlocked, with an authored comprehension question for this profile, not yet
## answered) - or "" if none exists. `unlocked_ids` is the caller-supplied combined list of
## GameState.creatures_met.keys() + GameState.keepsakes.keys(), kept as a plain Array param
## (not a direct GameState read) so this stays a deterministically-testable static function.
static func find_eligible_entry(unlocked_ids: Array, answered_ids: Dictionary, profile_id: String) -> String:
    for entry_id in unlocked_ids:
        if answered_ids.has(entry_id):
            continue
        if not ContentDefinitions.get_comprehension_question(entry_id, profile_id).is_empty():
            return entry_id
    return ""

## Pure logic: does the chosen answer match the entry's correct answer?
static func is_answer_correct(chosen_answer: String, correct_answer: String) -> bool:
    return chosen_answer == correct_answer

func show_check(speaker_name: String, entry_id: String) -> bool:
    var question: Dictionary = ContentDefinitions.get_comprehension_question(entry_id, GameState.selected_profile)
    if question.is_empty():
        return false

    _speaker_name = speaker_name
    _entry_id = entry_id
    _choices = question.get("choices", [])
    _correct_answer = str(question.get("correct", ""))
    if _choices.size() < 2:
        return false

    question_label.text = str(question.get("question", ""))
    first_button.text = str(_choices[0])
    second_button.text = str(_choices[1])
    visible = true
    return true

func _unhandled_input(event: InputEvent) -> void:
    if not visible or not event is InputEventKey:
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
    var line: String
    if is_answer_correct(selected_answer, _correct_answer):
        GameState.award_comprehension_bonus(_entry_id)
        line = "How wonderful!%s" % CORRECT_LINE_SUFFIX
    else:
        line = WRONG_LINE

    GameState.mark_comprehension_answered(_entry_id)
    visible = false
    dialogue_requested.emit(_speaker_name, line)
