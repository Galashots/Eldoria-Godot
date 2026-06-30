extends CharacterBody2D

@export var speed: float = 160.0

@onready var body: Sprite2D = $Body

const DIRECTION_TEXTURES := {
	"grade_2_mage": {
		"s": preload("res://assets/sprites/characters/mage_body_idle_s.png"),
		"se": preload("res://assets/sprites/characters/mage_body_idle_se.png"),
		"e": preload("res://assets/sprites/characters/mage_body_idle_e.png"),
		"ne": preload("res://assets/sprites/characters/mage_body_idle_ne.png"),
		"n": preload("res://assets/sprites/characters/mage_body_idle_n.png"),
	},
	"grade_5_adventurer": {
		"s": preload("res://assets/sprites/characters/adventurer_body_idle_s.png"),
		"se": preload("res://assets/sprites/characters/adventurer_body_idle_se.png"),
		"e": preload("res://assets/sprites/characters/adventurer_body_idle_e.png"),
		"ne": preload("res://assets/sprites/characters/adventurer_body_idle_ne.png"),
		"n": preload("res://assets/sprites/characters/adventurer_body_idle_n.png"),
	},
}

# Maps each of the 8 facings to one of the 5 rendered directions plus a
# flip_h flag, mirroring west/southwest/northwest from east/southeast/northeast.
const DIRECTION_MIRRORS := {
	"s": ["s", false],
	"se": ["se", false],
	"sw": ["se", true],
	"e": ["e", false],
	"w": ["e", true],
	"ne": ["ne", false],
	"nw": ["ne", true],
	"n": ["n", false],
}

# 8-way compass sectors in angle order, starting at 0 radians (east).
const COMPASS_DIRECTIONS := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

var facing: String = "s"

func _ready() -> void:
	GameState.profile_changed.connect(_on_profile_changed)
	_update_sprite()

func _on_profile_changed(_profile_id: String) -> void:
	_update_sprite()

func _update_sprite() -> void:
	var directions: Variant = DIRECTION_TEXTURES.get(GameState.selected_profile)
	if not directions:
		return
	var mirror: Array = DIRECTION_MIRRORS[facing]
	var texture: Texture2D = directions.get(mirror[0])
	if texture:
		body.texture = texture
		body.flip_h = mirror[1]

func _direction_from_vector(v: Vector2) -> String:
	var index := int(round(v.angle() / (PI / 4.0)))
	index = ((index % 8) + 8) % 8
	return COMPASS_DIRECTIONS[index]

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
		var new_facing := _direction_from_vector(input_vec)
		if new_facing != facing:
			facing = new_facing
			_update_sprite()

	velocity = input_vec * speed
	move_and_slide()
