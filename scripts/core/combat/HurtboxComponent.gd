extends Area2D
class_name HurtboxComponent

## Detects overlapping HitboxComponents (matched by group, not a dedicated physics layer -
## everything in this project still defaults to layer/mask 1, same as the existing
## interaction areas). Auto-discovers a sibling "HealthComponent" node (by name, not an
## exported node reference - a raw NodePath literal in .tscn text does not reliably
## resolve to a typed Node export on load) and applies damage to it automatically if
## found. Either way `hit_received` fires, so an owner without a HealthComponent sibling
## (the player, whose hp lives on GameState instead - see GameState.take_player_damage())
## can apply the damage itself.

signal hit_received(damage: int, hitbox: Area2D)

var health: HealthComponent

func _ready() -> void:
	add_to_group("hurtbox")
	area_entered.connect(_on_area_entered)
	health = get_parent().get_node_or_null("HealthComponent")

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
		return
	if area.get_parent() == get_parent():
		return # a hitbox never damages its own owner (e.g. a slime's contact hitbox vs. its own hurtbox)

	var dealt: int = area.damage if "damage" in area else 1
	if health:
		health.take_damage(dealt)
	hit_received.emit(dealt, area)

	if area.has_signal("landed"):
		area.landed.emit(self)
