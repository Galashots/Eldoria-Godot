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

var current_hp: int
var _hit_cooldown_remaining: float = 0.0

func _ready() -> void:
	current_hp = max_hp

func _process(delta: float) -> void:
	if _hit_cooldown_remaining > 0.0:
		_hit_cooldown_remaining = maxf(0.0, _hit_cooldown_remaining - delta)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or _hit_cooldown_remaining > 0.0:
		return

	current_hp = maxi(0, current_hp - amount)
	_hit_cooldown_remaining = hit_cooldown_sec
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()

func heal_to_full() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
