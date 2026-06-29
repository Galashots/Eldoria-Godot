extends CharacterBody2D

@export var speed: float = 160.0

func _physics_process(_delta: float) -> void:
    if GameState.selected_profile == "":
        velocity = Vector2.ZERO
        return

    var input_vec := Vector2.ZERO

    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vec.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vec.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vec.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vec.y += 1.0

    if input_vec.length() > 0.0:
        input_vec = input_vec.normalized()

    velocity = input_vec * speed
    move_and_slide()

