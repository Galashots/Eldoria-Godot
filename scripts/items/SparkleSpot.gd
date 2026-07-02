extends Area2D

## Discovery sparkle-spot pickup: a small hidden bonus scattered across a distinct map
## region. Mirrors Collectible.gd/CoinPickup.gd's pickup shape exactly (Area2D,
## body_entered -> CharacterBody2D check -> queue_free), but on touch it both awards a
## small coin bonus AND records a permanent "Places discovered" codex entry via
## GameState.discover_place() - bonus-only, nothing blocks or nags if it's missed.

@export var place_id: String = ""
@export var coin_reward: int = 1

var _collected: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    if GameState.has_discovered_place(place_id):
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if _collected:
        return
    if body is CharacterBody2D:
        _collected = true
        GameState.add_coins(coin_reward)
        GameState.discover_place(place_id)
        AudioManager.play_sfx("coin_chime")
        set_deferred("monitoring", false)
        PickupPop.play(get_node_or_null("Body"), queue_free)
