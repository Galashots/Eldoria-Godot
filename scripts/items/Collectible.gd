extends Area2D

@export var item_id: String = "golden_star"

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    if GameState.has_item(item_id):
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body is CharacterBody2D:
        GameState.add_item(item_id)
        queue_free()
