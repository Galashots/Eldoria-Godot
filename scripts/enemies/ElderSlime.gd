extends "res://scripts/enemies/MeadowSlime.gd"

## First mini-boss (expansion backlog slice): a tougher Meadow Slime variant. Reuses the
## whole MeadowSlime FSM/component architecture (HealthComponent, HitboxComponent,
## HurtboxComponent) rather than a new parallel monster script - a small subclass, since the
## one new behavior (a telegraphed windup lunge) needs an extra state MeadowSlime.gd doesn't
## have, so plain @export stat overrides on a MeadowSlime.tscn variant weren't enough.
##
## Placed once, at a clear mid-point of the M1 zone (see Main.tscn's "Bosses" node) -
## deliberately NOT under the "Enemies" node that Spawner.gd respawns, since an
## endlessly-respawning mini-boss would cheapen the "first tougher fight" moment. One per
## session; if the player wants to fight it again, a future slice can add that deliberately.

enum BossState { NORMAL, TELEGRAPH, LUNGE }

## Telegraphed windup (research: RESEARCH_NOTES.md §6.3 - every dangerous move must be
## clearly telegraphed before it lands). While telegraphing the slime flashes and pauses in
## place - a clear, fair visual tell - then lunges at the player's last-seen position.
@export var telegraph_duration_sec: float = 0.8
@export var lunge_duration_sec: float = 0.35
@export var lunge_speed: float = 260.0
## How close the player must be (while chasing) before a lunge is triggered.
@export var lunge_trigger_radius: float = 70.0
## Cooldown between lunges so it can't spam the telegraph/lunge over and over.
@export var lunge_cooldown_sec: float = 3.0

var _boss_state: BossState = BossState.NORMAL
var _telegraph_timer: float = 0.0
var _lunge_timer: float = 0.0
var _lunge_cooldown_remaining: float = 0.0
var _lunge_direction: Vector2 = Vector2.ZERO
var _flash_target: CanvasItem = null
var _flash_base_modulate: Color = Color.WHITE

func _ready() -> void:
	super._ready()
	_flash_target = get_node_or_null("Body")
	if _flash_target:
		_flash_base_modulate = _flash_target.modulate

func _physics_process(delta: float) -> void:
	if _lunge_cooldown_remaining > 0.0:
		_lunge_cooldown_remaining = maxf(0.0, _lunge_cooldown_remaining - delta)

	match _boss_state:
		BossState.TELEGRAPH:
			_process_telegraph(delta)
			return
		BossState.LUNGE:
			_process_lunge(delta)
			return
		BossState.NORMAL:
			pass

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and _lunge_cooldown_remaining <= 0.0 and _state == State.CHASE \
			and position.distance_to(player.position) <= lunge_trigger_radius:
		_start_telegraph(player.position)
		return

	super._physics_process(delta)

func _start_telegraph(player_position: Vector2) -> void:
	_boss_state = BossState.TELEGRAPH
	_telegraph_timer = telegraph_duration_sec
	_lunge_direction = position.direction_to(player_position)
	velocity = Vector2.ZERO
	move_and_slide()
	_apply_telegraph_flash(1.0)

func _process_telegraph(delta: float) -> void:
	_telegraph_timer -= delta
	_apply_telegraph_flash(telegraph_windup_intensity(_telegraph_timer, telegraph_duration_sec))
	if _telegraph_timer <= 0.0:
		_boss_state = BossState.LUNGE
		_lunge_timer = lunge_duration_sec
		_apply_telegraph_flash(0.0)

func _process_lunge(delta: float) -> void:
	_lunge_timer -= delta
	velocity = _lunge_direction * lunge_speed
	move_and_slide()
	if _lunge_timer <= 0.0:
		_boss_state = BossState.NORMAL
		_lunge_cooldown_remaining = lunge_cooldown_sec
		velocity = Vector2.ZERO

func _apply_telegraph_flash(intensity: float) -> void:
	if _flash_target == null:
		return
	_flash_target.modulate = _flash_base_modulate.lerp(Color.WHITE, intensity)

## Pure, unit-tested: 0.0 at the start of the windup, ramping to 1.0 right before the lunge
## fires - the flash gets more intense the closer the lunge is, giving the clearest warning
## right when it matters most. Mirrors HealthComponent.hit_reaction_intensity()'s pattern.
static func telegraph_windup_intensity(remaining: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return 1.0 - clampf(remaining / duration, 0.0, 1.0)

func _on_died() -> void:
	GameState.record_creature_met("elder_slime")
	GameState.award_keepsake("elder_slime_dewdrop")
	hurtbox.set_deferred("monitoring", false)
	contact_hitbox.set_deferred("monitorable", false)
	_spawn_coin_drop.call_deferred()
	AudioManager.play_sfx("slime_boing")

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
