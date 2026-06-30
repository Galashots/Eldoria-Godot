extends CharacterBody2D

@export var speed: float = 160.0

@onready var body: AnimatedSprite2D = $Body
@onready var armor: AnimatedSprite2D = $Armor

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

# Two extra mid-stride poses per direction. The walk loop alternates
# idle (neutral/passing pose) -> walk1 -> idle -> walk2, so only these two
# new poses are needed per direction, not a full frame-by-frame cycle.
const WALK_TEXTURES := {
	"grade_2_mage": {
		"s": [preload("res://assets/sprites/characters/mage_body_walk1_s.png"), preload("res://assets/sprites/characters/mage_body_walk2_s.png")],
		"se": [preload("res://assets/sprites/characters/mage_body_walk1_se.png"), preload("res://assets/sprites/characters/mage_body_walk2_se.png")],
		"e": [preload("res://assets/sprites/characters/mage_body_walk1_e.png"), preload("res://assets/sprites/characters/mage_body_walk2_e.png")],
		"ne": [preload("res://assets/sprites/characters/mage_body_walk1_ne.png"), preload("res://assets/sprites/characters/mage_body_walk2_ne.png")],
		"n": [preload("res://assets/sprites/characters/mage_body_walk1_n.png"), preload("res://assets/sprites/characters/mage_body_walk2_n.png")],
	},
	"grade_5_adventurer": {
		"s": [preload("res://assets/sprites/characters/adventurer_body_walk1_s.png"), preload("res://assets/sprites/characters/adventurer_body_walk2_s.png")],
		"se": [preload("res://assets/sprites/characters/adventurer_body_walk1_se.png"), preload("res://assets/sprites/characters/adventurer_body_walk2_se.png")],
		"e": [preload("res://assets/sprites/characters/adventurer_body_walk1_e.png"), preload("res://assets/sprites/characters/adventurer_body_walk2_e.png")],
		"ne": [preload("res://assets/sprites/characters/adventurer_body_walk1_ne.png"), preload("res://assets/sprites/characters/adventurer_body_walk2_ne.png")],
		"n": [preload("res://assets/sprites/characters/adventurer_body_walk1_n.png"), preload("res://assets/sprites/characters/adventurer_body_walk2_n.png")],
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

const WALK_FPS := 8.0

var facing: String = "s"
var _is_moving: bool = false
var _profile_frames: Dictionary = {}

func _ready() -> void:
	for profile_id: String in DIRECTION_TEXTURES.keys():
		_profile_frames[profile_id] = _build_sprite_frames(DIRECTION_TEXTURES[profile_id], WALK_TEXTURES.get(profile_id, {}))

	GameState.profile_changed.connect(_on_profile_changed)
	_update_sprite()

func _build_sprite_frames(idle_directions: Dictionary, walk_directions: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for dir_key: String in idle_directions.keys():
		var idle_texture: Texture2D = idle_directions[dir_key]

		var idle_anim := "idle_%s" % dir_key
		frames.add_animation(idle_anim)
		frames.set_animation_loop(idle_anim, true)
		frames.add_frame(idle_anim, idle_texture)

		var walk_anim := "walk_%s" % dir_key
		frames.add_animation(walk_anim)
		frames.set_animation_loop(walk_anim, true)
		frames.set_animation_speed(walk_anim, WALK_FPS)
		var walk_poses: Array = walk_directions.get(dir_key, [])
		if walk_poses.size() == 2:
			frames.add_frame(walk_anim, idle_texture)
			frames.add_frame(walk_anim, walk_poses[0])
			frames.add_frame(walk_anim, idle_texture)
			frames.add_frame(walk_anim, walk_poses[1])
		else:
			frames.add_frame(walk_anim, idle_texture)
	return frames

func _on_profile_changed(_profile_id: String) -> void:
	_update_sprite()

func _update_sprite() -> void:
	var frames: SpriteFrames = _profile_frames.get(GameState.selected_profile)
	if not frames:
		return
	var mirror: Array = DIRECTION_MIRRORS[facing]
	var anim_name := "%s_%s" % ["walk" if _is_moving else "idle", mirror[0]]
	if not frames.has_animation(anim_name):
		return
	body.sprite_frames = frames
	body.flip_h = mirror[1]
	if body.animation != anim_name or not body.is_playing():
		body.play(anim_name)

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

	_is_moving = input_vec.length() > 0.0
	if _is_moving:
		input_vec = input_vec.normalized()
		facing = _direction_from_vector(input_vec)

	_update_sprite()

	velocity = input_vec * speed
	move_and_slide()
