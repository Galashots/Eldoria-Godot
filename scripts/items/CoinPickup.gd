extends Area2D

@export var value: int = 1

var _collected: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if _collected:
        return
    if body is CharacterBody2D:
        _collected = true
        GameState.add_coins(value)
        set_deferred("monitoring", false)
        PickupPop.play(get_node_or_null("Body"), queue_free)
