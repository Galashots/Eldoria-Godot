extends StaticBody2D

## Diegetic session-end "rest" beat. Mirrors an NPC's interact pattern (see
## scripts/npcs/Yarrow.gd) but has no quest state: interacting always shows a warm,
## profile-aware confirmation, calls GameState.save_game(), and asks DialogueBox's caller
## (Main.tscn) to play a brief calm fade overlay. Purely a positive closure beat - bonus-only,
## no streaks, no timers, no "come back tomorrow" messaging, and nothing is ever lost by not
## resting. The child can keep playing immediately afterward.

signal dialogue_requested(speaker_name: String, line: String)
signal rested

@export var display_name: String = "The Campfire"

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var flame: Polygon2D = $Flame
@onready var flame_inner: Polygon2D = $FlameInner

var player_nearby: bool = false

func _ready() -> void:
    $InteractionArea.body_entered.connect(_on_body_entered)
    $InteractionArea.body_exited.connect(_on_body_exited)
    _start_flame_flicker()

## Cheap 2-frame-style flicker: a looping Tween gently scales the flame polygons up and down,
## same low-cost "juice" approach as HealthComponent's hit-flash tween elsewhere in this repo.
func _start_flame_flicker() -> void:
    var tween := create_tween()
    tween.set_loops()
    tween.tween_property(flame, "scale", Vector2(1.08, 0.92), 0.35).set_trans(Tween.TRANS_SINE)
    tween.tween_property(flame, "scale", Vector2(0.94, 1.06), 0.35).set_trans(Tween.TRANS_SINE)
    var inner_tween := create_tween()
    inner_tween.set_loops()
    inner_tween.tween_property(flame_inner, "scale", Vector2(0.92, 1.1), 0.3).set_trans(Tween.TRANS_SINE)
    inner_tween.tween_property(flame_inner, "scale", Vector2(1.06, 0.9), 0.3).set_trans(Tween.TRANS_SINE)

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
    GameState.save_game()
    dialogue_requested.emit(display_name, get_rest_message(GameState.selected_profile))
    rested.emit()

## Pure/static so it's deterministically unit-testable without a scene tree. Grade 2 gets a
## short plain message; Grade 5 a slightly richer one; unknown/empty profile falls back to a
## neutral line rather than crashing (mirrors Yarrow.gd's _get_offer_line() fallback shape).
static func get_rest_message(profile: String) -> String:
    if profile == "grade_2_mage":
        return "You rest by the warm fire. Your adventure is saved! See you next time!"
    if profile == "grade_5_adventurer":
        return "You settle by the crackling campfire and feel the day's adventures settle with you. Your progress is safely saved - rest easy, and continue whenever you're ready."
    return "You rest by the warm fire. Your progress is saved."

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
