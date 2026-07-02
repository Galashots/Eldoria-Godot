extends RefCounted
class_name PickupPop

## Shared "gentle pickup pop" helper for coin/collectible/sparkle-spot pickups
## (RESEARCH_NOTES.md §10.3 — a small squash-and-stretch scale pop is the highest-signal,
## lowest-cost "juice" for this audience; explicitly NO screen shake, kept small/quick).
##
## Mirrors HealthComponent's hit-flash precedent: a pure, unit-tested easing function drives
## a Tween that scales a sibling "Body" node up then back to rest, and the pickup delays its
## own queue_free() until the pop finishes instead of vanishing instantly. The reward itself
## (coins/items/codex entries) must always be awarded BEFORE the pop starts, so the pop can
## never delay or drop the award.

const POP_DURATION_SEC := 0.22
const POP_PEAK_SCALE := 1.3

## Pure, unit-tested easing for the pop: 1.0 (no change) at t=0, rises to POP_PEAK_SCALE
## partway through a quick grow, then settles back to 1.0 (rest) by t=duration. Returns a
## scale MULTIPLIER, not a delta, so callers can do
## `base_scale * pop_scale_multiplier(t, duration, peak)` directly.
static func pop_scale_multiplier(t: float, duration: float, peak: float = POP_PEAK_SCALE) -> float:
    if duration <= 0.0:
        return 1.0
    var progress := clampf(t / duration, 0.0, 1.0)
    # Quick grow to peak over the first third, gentle settle back to 1.0 over the rest -
    # a simple triangular envelope in "growth above 1.0" space, eased on both legs.
    var growth := peak - 1.0
    var intensity: float
    if progress < 0.35:
        intensity = ease(progress / 0.35, 0.4)
    else:
        intensity = 1.0 - ease((progress - 0.35) / 0.65, 0.6)
    return 1.0 + growth * clampf(intensity, 0.0, 1.0)

## Plays the pop tween on `body` (a CanvasItem, typically the pickup's sibling "Body" node)
## and calls `on_finished` once it settles. Safe no-op (calls on_finished immediately) if
## `body` is null or not yet inside the scene tree (e.g. a headless unit test that
## instantiates a pickup without adding it to a live tree - Tween requires a live tree), so
## a pickup missing a "Body" node - or a test double - still frees itself/finishes cleanly.
static func play(body: CanvasItem, on_finished: Callable, duration: float = POP_DURATION_SEC, peak: float = POP_PEAK_SCALE) -> void:
    if body == null or not body.is_inside_tree():
        on_finished.call()
        return

    var base_scale: Vector2 = body.scale
    var tween := body.create_tween()
    tween.tween_method(
        func(t: float): body.scale = base_scale * pop_scale_multiplier(t, duration, peak),
        0.0, duration, duration
    )
    tween.finished.connect(on_finished)
