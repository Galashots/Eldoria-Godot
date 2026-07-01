extends CharacterBody2D

signal dialogue_requested(speaker_name: String, line: String)
signal combat_question_requested

@export var speed: float = 160.0
@export var attack_base_damage: int = 1
@export var attack_reach: float = 24.0
@export var attack_active_sec: float = 0.15
@export var attack_cooldown_sec: float = 0.35

@onready var body: AnimatedSprite2D = $Body
@onready var armor: AnimatedSprite2D = $Armor
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var player_hurtbox: HurtboxComponent = $PlayerHurtbox

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

# Where the attack hitbox is placed each swing, one unit vector per facing.
const FACING_VECTORS := {
	"e": Vector2(1, 0),
	"se": Vector2(0.7071, 0.7071),
	"s": Vector2(0, 1),
	"sw": Vector2(-0.7071, 0.7071),
	"w": Vector2(-1, 0),
	"nw": Vector2(-0.7071, -0.7071),
	"n": Vector2(0, -1),
	"ne": Vector2(0.7071, -0.7071),
}

const WALK_FPS := 8.0

# Tier 1 (Leather) armor idle art only exists as idle poses (no walk-cycle frames yet), so
# armored walking falls back to a static armored idle pose via _build_sprite_frames' existing
# "no walk poses" branch.
const ARMOR_TIER1_TEXTURES := {
	"grade_2_mage": {
		"s": preload("res://assets/sprites/characters/mage_body_idle_tier1_s.png"),
		"se": preload("res://assets/sprites/characters/mage_body_idle_tier1_se.png"),
		"e": preload("res://assets/sprites/characters/mage_body_idle_tier1_e.png"),
		"ne": preload("res://assets/sprites/characters/mage_body_idle_tier1_ne.png"),
		"n": preload("res://assets/sprites/characters/mage_body_idle_tier1_n.png"),
	},
	"grade_5_adventurer": {
		"s": preload("res://assets/sprites/characters/adventurer_body_idle_tier1_s.png"),
		"se": preload("res://assets/sprites/characters/adventurer_body_idle_tier1_se.png"),
		"e": preload("res://assets/sprites/characters/adventurer_body_idle_tier1_e.png"),
		"ne": preload("res://assets/sprites/characters/adventurer_body_idle_tier1_ne.png"),
		"n": preload("res://assets/sprites/characters/adventurer_body_idle_tier1_n.png"),
	},
}

var facing: String = "s"
var _is_moving: bool = false
var _profile_frames: Dictionary = {}
var _profile_armor_frames: Dictionary = {}

var _spawn_position: Vector2
var _attack_active_remaining: float = 0.0
var _attack_cooldown_remaining: float = 0.0

func _ready() -> void:
	add_to_group("player")

	for profile_id: String in DIRECTION_TEXTURES.keys():
		_profile_frames[profile_id] = _build_sprite_frames(DIRECTION_TEXTURES[profile_id], WALK_TEXTURES.get(profile_id, {}))
	for profile_id: String in ARMOR_TIER1_TEXTURES.keys():
		_profile_armor_frames[profile_id] = _build_sprite_frames(ARMOR_TIER1_TEXTURES[profile_id], {})

	GameState.profile_changed.connect(_on_profile_changed)
	GameState.armor_equipped.connect(_on_armor_equipped)
	GameState.player_died.connect(_on_player_died)
	_update_sprite()

	_spawn_position = position
	attack_hitbox.landed.connect(_on_attack_landed)
	player_hurtbox.hit_received.connect(_on_player_hurtbox_hit)

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

func _on_armor_equipped(_tier: int) -> void:
	_update_sprite()

func _update_sprite() -> void:
	var frames_dict := _profile_armor_frames if GameState.equipped_armor_tier > 0 else _profile_frames
	var frames: SpriteFrames = frames_dict.get(GameState.selected_profile)
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

func _physics_process(delta: float) -> void:
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
	_process_attack(delta)

	velocity = input_vec * speed
	move_and_slide()

func _process_attack(delta: float) -> void:
	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)

	if _attack_active_remaining > 0.0:
		_attack_active_remaining = maxf(0.0, _attack_active_remaining - delta)
		if _attack_active_remaining == 0.0:
			attack_hitbox.monitorable = false
			attack_hitbox.visible = false

	if Input.is_action_just_pressed("attack") and _attack_cooldown_remaining <= 0.0:
		_swing_attack()

func _swing_attack() -> void:
	_attack_cooldown_remaining = attack_cooldown_sec
	_attack_active_remaining = attack_active_sec

	var direction: Vector2 = FACING_VECTORS.get(facing, Vector2.DOWN)
	attack_hitbox.position = direction * attack_reach
	attack_hitbox.damage = int(round(attack_base_damage * GameState.get_combat_multiplier()))
	attack_hitbox.monitorable = true
	attack_hitbox.visible = true

func _on_attack_landed(_hurtbox: Area2D) -> void:
	if not GameState.can_trigger_combat_question():
		return

	GameState.mark_combat_question_triggered()
	combat_question_requested.emit()

func _on_player_hurtbox_hit(_damage: int, _hitbox: Area2D) -> void:
	GameState.take_player_damage(_damage)

func _on_player_died() -> void:
	position = _spawn_position
	GameState.heal_player_to_full()
	dialogue_requested.emit("", "You feel dizzy and stumble home to rest. You're okay now!")
