extends Area2D

@export var item_id: String = "golden_star"

var _collected: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    if GameState.has_item(item_id):
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if _collected:
        return
    if body is CharacterBody2D:
        _collected = true
        GameState.add_item(item_id)
        set_deferred("monitoring", false)
        PickupPop.play(get_node_or_null("Body"), queue_free)
