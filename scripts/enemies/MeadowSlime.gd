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

func _pick_wander_target() -> void:
	var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	_wander_target = _home_position + offset
	_state = State.WANDER

func _on_died() -> void:
	hurtbox.set_deferred("monitoring", false)
	contact_hitbox.set_deferred("monitorable", false)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
