extends CanvasLayer

@onready var objective_label: Label = $MarginContainer/ObjectiveLabel

func _ready() -> void:
    GameState.item_added.connect(_on_item_added)
    _update_objective()

func _on_item_added(_item_id: String, _amount: int) -> void:
    _update_objective()

func _update_objective() -> void:
    if GameState.has_item("golden_star"):
        objective_label.text = "Objective complete: Golden star collected!"
    else:
        objective_label.text = "Objective: Collect the golden star."
