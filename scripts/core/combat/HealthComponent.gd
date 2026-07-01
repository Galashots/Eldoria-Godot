extends Node
class_name HealthComponent

## Reusable hp tracker for combat entities. Not persisted - GameState.player_hp remains
## the single source of truth for the player's saved hp; this component is for enemies
## (and any future transient combat actor) whose hp resets each time they're instanced.

signal health_changed(current: int, max: int)
signal died

@export var max_hp: int = 3
## Brief immunity after any hit, so standing in continuous contact with an enemy (or
## being clipped by a lingering hitbox) doesn't deal damage every physics frame.
@export var hit_cooldown_sec: float = 0.5

## Hit-feedback "juice" (RESEARCH_NOTES §7.1): on damage the owner's sprite briefly pops
## bigger and tints toward white so a landed hit reads instantly. Kept gentle (short, small)
## for a Grade 2/5 audience - no screen shake, no hit-stop. The sprite to react is
## auto-discovered as a sibling node named "Body" in _ready() (avoids the unreliable
## NodePath-export resolution noted in docs/CURRENT_STATE.md's M2 writeup).
const FLASH_DURATION_SEC := 0.08
const FLASH_POP_SCALE := 0.25

var current_hp: int
var _hit_cooldown_remaining: float = 0.0

var _flash_target: CanvasItem = null
var _flash_base_modulate: Color = Color.WHITE
var _flash_base_scale: Vector2 = Vector2.ONE
var _flash_remaining: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	var body := get_parent().get_node_or_null("Body")
	if body is CanvasItem:
		_flash_target = body
		_flash_base_modulate = _flash_target.modulate
		_flash_base_scale = _flash_target.scale

func _process(delta: float) -> void:
	if _hit_cooldown_remaining > 0.0:
		_hit_cooldown_remaining = maxf(0.0, _hit_cooldown_remaining - delta)

	if _flash_remaining > 0.0:
		_flash_remaining = maxf(0.0, _flash_remaining - delta)
		_apply_flash()

func take_damage(amount: int) -> void:
	if current_hp <= 0 or _hit_cooldown_remaining > 0.0:
		return

	current_hp = maxi(0, current_hp - amount)
	_hit_cooldown_remaining = hit_cooldown_sec
	_start_flash()
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()

func _start_flash() -> void:
	if _flash_target == null:
		return
	_flash_remaining = FLASH_DURATION_SEC
	_apply_flash()

func _apply_flash() -> void:
	if _flash_target == null:
		return
	var intensity := hit_reaction_intensity(_flash_remaining, FLASH_DURATION_SEC)
	_flash_target.modulate = _flash_base_modulate.lerp(Color.WHITE, intensity)
	_flash_target.scale = _flash_base_scale * (1.0 + FLASH_POP_SCALE * intensity)

## Pure, unit-tested easing for the hit reaction: 1.0 at the instant of the hit
## (remaining == duration) decaying linearly to 0.0 when the flash ends. Both the sprite
## tint and the pop scale are driven by this, so testing it covers the timing for both.
static func hit_reaction_intensity(remaining: float, duration: float) -> float:
	if duration <= 0.0:
		return 0.0
	return clampf(remaining / duration, 0.0, 1.0)

func heal_to_full() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
