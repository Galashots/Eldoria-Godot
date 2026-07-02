extends Node2D

## Ambient particle pass (expansion backlog): soft, region-flavored atmosphere particles -
## drifting pollen over the flower meadow, gentle fireflies near the forest edge and lake.
## Deliberately the cheapest of the two spec'd approaches: a few small fixed CPUParticles2D
## emitters placed once at each region's existing landmark position (the same positions the
## "Discovery sparkle-spots" slice already anchored its SparkleSpot props to - see
## scenes/main/Main.tscn's FlowerMeadowSparkle/ForestEdgeSparkle/LakeShoreSparkle), rather than
## one emitter that follows the player and polls region_for_position() every frame. This node
## just wraps a single CPUParticles2D and applies a named preset (PRESETS) to it in _ready();
## no per-frame logic, no collision, purely visual.
##
## Presets are pure data plus a pure static lookup (get_preset()), unit-tested in
## tests/particle_tests.gd, so the region -> preset mapping is verifiable without a scene tree.
## Region *geometry* (REGION_RECTS) still lives solely in AudioManager.gd, reused as-is per the
## slice's explicit sequencing note - this file only adds a visual preset per region name and
## does not duplicate any rect data.

## One entry per supported region name (matching AudioManager.REGION_RECTS keys). Each preset is
## deliberately sparse/slow/low-alpha per docs/art/STYLE_GUIDE.md's "keep it gentle" rule -
## atmosphere, never visual noise. Colors are drawn from/near the existing gen_tileset.py flower
## palette (warm yellow/pink/lavender) and a soft warm firefly glow.
const PRESETS := {
    "flower_meadow": {
        "amount": 10,
        "lifetime": 6.0,
        "spread_x": 420.0,
        "spread_y": 260.0,
        "color": Color(1.0, 0.95, 0.55, 0.35),
        "particle_size": 3.0,
        "gravity": Vector2(0.0, -4.0),
        "initial_velocity_min": 4.0,
        "initial_velocity_max": 10.0,
    },
    "forest_edge": {
        "amount": 6,
        "lifetime": 5.0,
        "spread_x": 260.0,
        "spread_y": 420.0,
        "color": Color(1.0, 0.9, 0.5, 0.4),
        "particle_size": 3.5,
        "gravity": Vector2(0.0, 0.0),
        "initial_velocity_min": 3.0,
        "initial_velocity_max": 8.0,
    },
    "lake": {
        "amount": 5,
        "lifetime": 5.0,
        "spread_x": 300.0,
        "spread_y": 220.0,
        "color": Color(0.95, 1.0, 0.85, 0.35),
        "particle_size": 3.0,
        "gravity": Vector2(0.0, 0.0),
        "initial_velocity_min": 3.0,
        "initial_velocity_max": 7.0,
    },
}

## Which region preset this emitter should use. Set per-instance in Main.tscn (mirrors
## SparkleSpot's exported place_id pattern).
@export var region: String = "flower_meadow"

@onready var _particles: CPUParticles2D = $Particles

func _ready() -> void:
    apply_preset(_particles, get_preset(region))

## Pure lookup (unit-tested): returns the preset dict for a region name, or an empty dict if the
## region has no ambient-particle preset (some regions, e.g. village_green/rocky_border, are
## deliberately left without ambient particles - not every region needs one).
static func get_preset(region_name: String) -> Dictionary:
    return PRESETS.get(region_name, {})

## Applies a preset dictionary to a CPUParticles2D node. Separated from _ready() so it's easy to
## reason about/reuse; a missing/empty preset just disables emission rather than erroring.
static func apply_preset(particles: CPUParticles2D, preset: Dictionary) -> void:
    if preset.is_empty():
        particles.emitting = false
        return

    particles.emitting = true
    particles.amount = preset.get("amount", 6)
    particles.lifetime = preset.get("lifetime", 5.0)
    particles.preprocess = preset.get("lifetime", 5.0)
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    particles.emission_rect_extents = Vector2(preset.get("spread_x", 200.0), preset.get("spread_y", 200.0)) * 0.5
    particles.direction = Vector2(0.0, -1.0)
    particles.spread = 180.0
    particles.gravity = preset.get("gravity", Vector2.ZERO)
    particles.initial_velocity_min = preset.get("initial_velocity_min", 3.0)
    particles.initial_velocity_max = preset.get("initial_velocity_max", 8.0)
    particles.scale_amount_min = preset.get("particle_size", 3.0)
    particles.scale_amount_max = preset.get("particle_size", 3.0)
    particles.color = preset.get("color", Color(1.0, 1.0, 1.0, 0.3))
