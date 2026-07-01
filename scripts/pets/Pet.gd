extends CharacterBody2D

## Companion pet (M4). Follow-only: trails the player, never fights (no HealthComponent /
## Hitbox / Hurtbox - pet combat is explicitly out of scope for this slice, see
## docs/design/PETS.md). Faster than the player (speed 160) so it never lags permanently.

@export var move_speed: float = 220.0
@export var stop_distance: float = 24.0

var follow_target: Node2D = null

func _physics_process(_delta: float) -> void:
	if follow_target == null:
		velocity = Vector2.ZERO
		return

	if position.distance_to(follow_target.position) > stop_distance:
		velocity = position.direction_to(follow_target.position) * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
