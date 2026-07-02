extends CharacterBody2D

## First monster (M2 of the Phase 2 roadmap). Deliberately low-threat: slow, low hp, small
## contact damage - the "hack and slash" here is meant to feel safe and forgiving for a
## Grade 2/5 audience, not punishing. Placeholder green-blob art; see the Meadow Slime
## ChatGPT concept prompt in docs/design/ for the real sprite once this is proven live.

enum State { IDLE, WANDER, CHASE }

@export var move_speed: float = 40.0
@export var aggro_radius: float = 120.0
@export var wander_radius: float = 80.0
@export var idle_pause_sec: float = 1.5
@export var contact_damage: int = 1
@export var coin_drop_value: int = 1

## Bonus-only extra-coin chance on top of the guaranteed coin_drop_value above (never a
## replacement for it - see docs/design/GEAR_AND_ECONOMY.md's "Bonus drop rule"). 0.12 (12%)
## sits in the ~10-15% range the backlog slice suggested; tune in-engine from here, it's a
## single exported var, not a hardcoded literal buried in logic.
@export_range(0.0, 1.0, 0.01) var bonus_coin_chance: float = 0.12

const CoinPickupScene := preload("res://scenes/items/CoinPickup.tscn")

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var contact_hitbox: HitboxComponent = $ContactHitbox

var _state: State = State.IDLE
var _home_position: Vector2
var _wander_target: Vector2
var _state_timer: float = 0.0

func _ready() -> void:
	_home_position = position
	health.died.connect(_on_died)
	contact_hitbox.damage = contact_damage

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D

	if player and position.distance_to(player.position) <= aggro_radius:
		_state = State.CHASE
	elif _state == State.CHASE:
		_state = State.IDLE
		_state_timer = 0.0

	match _state:
		State.CHASE:
			velocity = position.direction_to(player.position) * move_speed
		State.IDLE:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_pick_wander_target()
		State.WANDER:
			var to_target := position.direction_to(_wander_target)
			if position.distance_to(_wander_target) < 4.0:
				_state = State.IDLE
				_state_timer = idle_pause_sec
				velocity = Vector2.ZERO
			else:
				velocity = to_target * move_speed

	move_and_slide()

func _spawn_coin_drop() -> void:
	_spawn_one_coin(coin_drop_value)

	# Bonus-only: an occasional *additional* coin, never a reduction of the guaranteed drop
	# above. rolls_bonus_coin() is a pure function (takes the random roll as an argument) so
	# the probability logic is deterministically unit-testable without a scene tree.
	if rolls_bonus_coin(bonus_coin_chance, randf()):
		_spawn_one_coin(1)

func _spawn_one_coin(coin_value: int) -> void:
	var coin := CoinPickupScene.instantiate()
	coin.value = coin_value
	coin.global_position = global_position
	get_parent().add_child(coin)

## Pure logic, no engine RNG call inside - pass an explicit roll in [0.0, 1.0) so tests can
## assert both the "misses" and "hits" branches deterministically.
static func rolls_bonus_coin(chance: float, roll: float) -> bool:
	return roll < chance

func _pick_wander_target() -> void:
	var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	_wander_target = _home_position + offset
	_state = State.WANDER

func _on_died() -> void:
	GameState.record_creature_met("meadow_slime")
	hurtbox.set_deferred("monitoring", false)
	contact_hitbox.set_deferred("monitorable", false)
	_spawn_coin_drop.call_deferred()
	AudioManager.play_sfx("slime_boing")

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
