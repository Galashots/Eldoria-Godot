extends CharacterBody2D

@export var speed: float = 160.0

@onready var body: Sprite2D = $Body

const PROFILE_TEXTURES := {
	"grade_2_mage": preload("res://assets/sprites/characters/hero_body_idle_s.png"),
	"grade_5_adventurer": preload("res://assets/sprites/characters/adventurer_body_idle_s.png"),
}

func _ready() -> void:
	GameState.profile_changed.connect(_on_profile_changed)
	_update_sprite()

func _on_profile_changed(_profile_id: String) -> void:
	_update_sprite()

func _update_sprite() -> void:
	var texture: Texture2D = PROFILE_TEXTURES.get(GameState.selected_profile)
	if texture:
		body.texture = texture

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
