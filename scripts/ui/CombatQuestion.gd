extends CanvasLayer

## Combat's damage-multiplier question (see GameState.answer_combat_question()). Distinct
## from LearningCheck on purpose: it has no quest coupling, never blocks the fiction, and
## dismisses itself the instant an answer is chosen since combat keeps moving underneath it.
## Numeracy-only, matching the already-confirmed subject scope in
## docs/design/CURRICULUM_MAP.md (no new subject introduced for combat).

const QUESTION_POOL := {
	"grade_2_mage": [
		{"question": "What is 2 + 3?", "choices": ["5", "4"], "correct": "5"},
		{"question": "Which is bigger: 8 or 5?", "choices": ["8", "5"], "correct": "8"},
		{"question": "What is 4 + 4?", "choices": ["8", "7"], "correct": "8"},
	],
	"grade_5_adventurer": [
		{"question": "What is 7 x 8?", "choices": ["56", "54"], "correct": "56"},
		{"question": "What is 1/2 + 1/4?", "choices": ["3/4", "2/4"], "correct": "3/4"},
		{"question": "What is 9 x 6?", "choices": ["54", "52"], "correct": "54"},
	],
}

@onready var question_label: Label = $PanelContainer/VBoxContainer/QuestionLabel
@onready var first_button: Button = $PanelContainer/VBoxContainer/FirstAnswerButton
@onready var second_button: Button = $PanelContainer/VBoxContainer/SecondAnswerButton

var _correct_answer: String = ""
var _choices: Array = []

func _ready() -> void:
	visible = false
	first_button.pressed.connect(_on_first_answer_pressed)
	second_button.pressed.connect(_on_second_answer_pressed)

func show_question() -> void:
	var pool: Array = QUESTION_POOL.get(GameState.selected_profile, [])
	if pool.is_empty():
		return

	var picked: Dictionary = pool[randi() % pool.size()]
	_choices = picked["choices"]
	_correct_answer = picked["correct"]
	question_label.text = picked["question"]
	first_button.text = str(_choices[0])
	second_button.text = str(_choices[1])
	visible = true

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

	var correct := str(_choices[index]) == _correct_answer
	GameState.answer_combat_question(correct)
	visible = false
