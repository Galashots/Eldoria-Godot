extends Node2D

## Gentle repeatable coin faucet (expansion backlog slice). Watches the Meadow Slime children
## already placed under Main.tscn's "Enemies" node, remembers each one's spawn position, and
## re-instances a fresh MeadowSlime at that position after a slow, tunable delay once the
## original dies - capped so the live count never exceeds the original count (no crowding).
## Deliberately a small standalone node (disjoint from MeadowSlime.gd) per the backlog's
## "not a rewrite of the slime" acceptance criterion.

const MeadowSlimeScene := preload("res://scenes/enemies/MeadowSlime.tscn")

## Slow/gentle by design (NORTH_STAR: non-punitive, calm pacing) - a defeated area stays
## quiet for a while before offering more coins, not an instant refill.
@export var respawn_delay_sec: float = 25.0

var _spawn_points: Array[Vector2] = []
var _live_count: int = 0
var _pending_respawns: Array[float] = []  # seconds remaining, one entry per scheduled respawn

func _ready() -> void:
    for child in get_children():
        if child is CharacterBody2D:
            _spawn_points.append(child.position)
            _live_count += 1
            child.tree_exited.connect(_on_slime_tree_exited)

func _process(delta: float) -> void:
    var i := _pending_respawns.size() - 1
    while i >= 0:
        _pending_respawns[i] -= delta
        if _pending_respawns[i] <= 0.0:
            _pending_respawns.remove_at(i)
            _spawn_slime()
        i -= 1

func _on_slime_tree_exited() -> void:
    _live_count -= 1
    if should_schedule_respawn(_live_count, _pending_respawns.size(), _spawn_points.size()):
        _pending_respawns.append(respawn_delay_sec)

func _spawn_slime() -> void:
    if _spawn_points.is_empty():
        return
    var slime := MeadowSlimeScene.instantiate()
    slime.position = _spawn_points[_live_count % _spawn_points.size()]
    slime.y_sort_enabled = true
    add_child(slime)
    _live_count += 1
    slime.tree_exited.connect(_on_slime_tree_exited)

## Pure logic: decide whether a newly-vacated slot should get a scheduled respawn, given the
## current live count, how many respawns are already pending, and the original spawn-point
## cap. No engine calls, so this is deterministically unit-testable without a scene tree.
static func should_schedule_respawn(live_count: int, pending_count: int, max_count: int) -> bool:
    return live_count + pending_count < max_count

## Pure logic: given a list of remaining-seconds-until-respawn, return how many are due (<=
## 0.0) this tick. Mirrors the countdown-then-fire shape used in _process() above.
static func count_due(pending_seconds: Array, elapsed: float) -> int:
    var due := 0
    for remaining in pending_seconds:
        if remaining - elapsed <= 0.0:
            due += 1
    return due
