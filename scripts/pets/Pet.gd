extends CharacterBody2D

## First companion pet (M4 of the Phase 2 roadmap). Follows the player only - no combat, no
## wander/idle states, no aggro radius. Reuses the chase-state movement already proven in
## scripts/enemies/MeadowSlime.gd (direction_to * move_speed, move_and_slide()), stripped
## down since a pet never needs anything but "close the gap." Placeholder colored-polygon
## art, per the bootstrap-then-real-art order used for every prior NPC/monster/item.

@export var move_speed: float = 220.0
@export var stop_distance: float = 24.0

var follow_target: Node2D = null

func _physics_process(_delta: float) -> void:
	if follow_target == null or not is_instance_valid(follow_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if position.distance_to(follow_target.position) > stop_distance:
		velocity = position.direction_to(follow_target.position) * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
