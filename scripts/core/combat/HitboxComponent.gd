extends Area2D
class_name HitboxComponent

## A brief damage-dealing zone. Owners toggle `monitoring`/`visible` on for the active
## swing/contact window and off otherwise, rather than adding/removing the node, so a
## single hitbox can be reused every attack. `damage` is set by the owner right before
## activating (e.g. base damage * the player's current combat multiplier).

## Fired by the HurtboxComponent this hitbox connects with, so the attacker can react to
## landing a hit (e.g. the player triggering a combat math question) without needing to
## poll or duplicate the overlap detection HurtboxComponent already does.
signal landed(hurtbox: Area2D)

@export var damage: int = 1

func _ready() -> void:
	add_to_group("hitbox")
