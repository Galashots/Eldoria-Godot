extends CanvasLayer

## Combat's damage-multiplier question (see GameState.answer_combat_question()). Distinct
## from LearningCheck on purpose: it has no quest coupling, never blocks the fiction, and
## dismisses itself the instant an answer is chosen since combat keeps moving underneath it.
## Numeracy-only, matching the already-confirmed subject scope in
## docs/design/CURRICULUM_MAP.md (no new subject introduced for combat).
##
## Pool expansion (expansion backlog "Expand combat numeracy pool + gentle ramp"): each
## profile pool grew from 3 to 12+ items, ordered as a gentle difficulty ramp per
## RESEARCH_NOTES.md §10.2 (a tiny pool causes "early repetition"). Grade 2 ramps
## +1/+2 sums -> small teen sums -> coin value/comparison; Grade 5 ramps single-digit x ->
## two-digit x/division -> halves -> quarters/thirds -> money totals. The draw itself is a
## small pure/static function, pick_next_index(), mirroring MeadowSlime.rolls_bonus_coin()'s
## deterministic-test precedent, so the no-immediate-repeat rule is unit-testable without a
## scene tree.

const QUESTION_POOL := {
	"grade_2_mage": [
		# Single-digit +/- (easiest)
		{"question": "What is 2 + 3?", "choices": ["5", "4"], "correct": "5"},
		{"question": "What is 4 + 4?", "choices": ["8", "7"], "correct": "8"},
		{"question": "What is 6 - 2?", "choices": ["4", "3"], "correct": "4"},
		{"question": "What is 5 + 1?", "choices": ["6", "7"], "correct": "6"},
		# Small teen sums
		{"question": "What is 9 + 3?", "choices": ["12", "11"], "correct": "12"},
		{"question": "What is 7 + 6?", "choices": ["13", "12"], "correct": "13"},
		{"question": "What is 15 - 4?", "choices": ["11", "10"], "correct": "11"},
		{"question": "What is 8 + 8?", "choices": ["16", "15"], "correct": "16"},
		# Coin values / comparison
		{"question": "Which is bigger: 8 or 5?", "choices": ["8", "5"], "correct": "8"},
		{"question": "Which coin is worth more: a nickel or a penny?", "choices": ["nickel", "penny"], "correct": "nickel"},
		{"question": "Which coin is worth more: a dime or a nickel?", "choices": ["dime", "nickel"], "correct": "dime"},
		{"question": "A penny is worth 1 cent. How much are 2 pennies?", "choices": ["2 cents", "3 cents"], "correct": "2 cents"},
	],
	"grade_5_adventurer": [
		# Single-digit x (easiest)
		{"question": "What is 6 x 7?", "choices": ["42", "40"], "correct": "42"},
		{"question": "What is 8 x 4?", "choices": ["32", "36"], "correct": "32"},
		{"question": "What is 7 x 8?", "choices": ["56", "54"], "correct": "56"},
		{"question": "What is 9 x 6?", "choices": ["54", "52"], "correct": "54"},
		# Two-digit x / simple division
		{"question": "What is 12 x 4?", "choices": ["48", "46"], "correct": "48"},
		{"question": "What is 15 x 3?", "choices": ["45", "42"], "correct": "45"},
		{"question": "What is 36 / 6?", "choices": ["6", "5"], "correct": "6"},
		{"question": "What is 48 / 8?", "choices": ["6", "7"], "correct": "6"},
		# Fractions - halves and quarters/thirds
		{"question": "What is 1/2 + 1/4?", "choices": ["3/4", "2/4"], "correct": "3/4"},
		{"question": "What is 1/2 of 20?", "choices": ["10", "8"], "correct": "10"},
		{"question": "What is 1/3 of 9?", "choices": ["3", "4"], "correct": "3"},
		# Money totals
		{"question": "A wand costs $12 and a hat costs $5. What is the total?", "choices": ["$17", "$16"], "correct": "$17"},
	],
}

@onready var question_label: Label = $PanelContainer/VBoxContainer/QuestionLabel
@onready var first_button: Button = $PanelContainer/VBoxContainer/FirstAnswerButton
@onready var second_button: Button = $PanelContainer/VBoxContainer/SecondAnswerButton

var _correct_answer: String = ""
var _choices: Array = []
var _last_index: int = -1

func _ready() -> void:
	visible = false
	first_button.pressed.connect(_on_first_answer_pressed)
	second_button.pressed.connect(_on_second_answer_pressed)

func show_question() -> void:
	var pool: Array = QUESTION_POOL.get(GameState.selected_profile, [])
	if pool.is_empty():
		return

	var index := pick_next_index(pool.size(), _last_index, randf())
	_last_index = index

	var picked: Dictionary = pool[index]
	_choices = picked["choices"]
	_correct_answer = picked["correct"]
	question_label.text = picked["question"]
	first_button.text = str(_choices[0])
	second_button.text = str(_choices[1])
	visible = true

## Pure logic, no engine RNG call inside - pass an explicit roll in [0.0, 1.0) so tests can
## assert the no-immediate-repeat property deterministically. Picks a random index in
## [0, pool_size) that is never equal to last_index, by drawing from the remaining
## (pool_size - 1) slots and shifting past last_index. A single-item pool (pool_size <= 1)
## has no alternative to draw from, so it always returns 0 rather than dividing by zero or
## looping forever.
static func pick_next_index(pool_size: int, last_index: int, roll: float) -> int:
	if pool_size <= 1:
		return 0

	if last_index < 0 or last_index >= pool_size:
		return int(roll * pool_size) % pool_size

	var draw := int(roll * (pool_size - 1)) % (pool_size - 1)
	if draw >= last_index:
		draw += 1
	return draw

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
