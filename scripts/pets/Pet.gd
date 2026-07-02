extends CharacterBody2D

## Companion pet (M4, extended for the second-pet slice). Follow-only: trails the player,
## never fights (no HealthComponent / Hitbox / Hurtbox - pet combat is explicitly out of scope,
## see docs/design/PETS.md). Faster than the player (speed 160) so it never lags permanently.
##
## Sprite selection is data-driven rather than duplicating this scene per species: Player.gd
## sets `pet_id` before adding this to the tree, and `_ready()` looks up that pet's
## PetDefinition. If it has sprite_frame1_path/sprite_frame2_path set, a fresh 2-frame idle-bob
## SpriteFrames is built from those textures; otherwise Pet.tscn's baked-in SpriteFrames (Mossy's
## original art) is left untouched, so Mossy needs no data changes to keep working.

@export var move_speed: float = 220.0
@export var stop_distance: float = 24.0

## Which PetDefinition this instance represents. "" (the default, used when Pet.tscn is opened
## directly in the editor) keeps the scene's baked-in SpriteFrames.
var pet_id: String = ""

var follow_target: Node2D = null

@onready var body: AnimatedSprite2D = $Body

func _ready() -> void:
	_apply_sprite_for_pet_id()

func _apply_sprite_for_pet_id() -> void:
	if pet_id == "":
		return

	var pet := ContentDefinitions.get_pet(pet_id)
	if pet == null or pet.sprite_frame1_path == "" or pet.sprite_frame2_path == "":
		return

	var frame1: Texture2D = load(pet.sprite_frame1_path)
	var frame2: Texture2D = load(pet.sprite_frame2_path)
	if frame1 == null or frame2 == null:
		return

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 2.5)
	frames.add_frame("idle", frame1)
	frames.add_frame("idle", frame2)

	body.sprite_frames = frames
	body.animation = "idle"
	body.play("idle")

func _physics_process(_delta: float) -> void:
	if follow_target == null:
		velocity = Vector2.ZERO
		return

	if position.distance_to(follow_target.position) > stop_distance:
		velocity = position.direction_to(follow_target.position) * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
