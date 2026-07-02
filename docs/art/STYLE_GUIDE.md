# Eldoria-Godot Style Guide

This guide keeps visual work consistent while the project is still using placeholders.

## Visual direction

Eldoria should feel like a bright, readable, family-friendly top-down fantasy RPG.

Priorities:

- clear silhouettes
- readable sprites at small sizes
- warm village-fantasy tone
- simple shapes before detail
- strong contrast between player, NPCs, items, and ground

## Pixel-art rules

For early game-ready sprites:

- use transparent PNG backgrounds
- avoid blur and noisy edges
- keep outlines readable
- keep palettes limited
- avoid tiny details that disappear at 32x32

## Placeholder color language

Until final art arrives, use strong readable colors:

- Player: blue
- Elder Rowan: purple
- Mira the Gardener: green
- Golden star: yellow/gold
- Glowing herb: bright green
- Obstacles/wood: brown
- Floor/grass: green

## Character and NPC guidance

NPCs should be distinct even as placeholders:

- unique silhouette
- unique color
- unique position in village
- short readable name
- quest role reflected in color/shape

## Item guidance

Items should be visually distinct from the ground and NPCs.

- one clear central shape
- high contrast
- no tiny clutter
- readable at 16x16 or 32x32

## UI guidance

UI should stay simple and readable for children.

- large text
- short sentences
- strong contrast
- clear button labels
- avoid dense paragraphs in gameplay

Grade 2 text should be especially short and direct.

## Art direction one-pager — what "epic" means for Eldoria (2026-07-01)

Added after the owner's "cool backgrounds, epic art" mandate and the palette/atmosphere
research in `docs/design/RESEARCH_NOTES.md` §9. This is the mood target the atmosphere/art
expansion slices serve. It **extends**, does not replace, the rules above.

**"Epic" here is not detail — it is mood and cohesion.** At this game's low-fi scale, grandeur
comes from a bright, harmonious world that feels *alive and warm*, readable at a glance by a
Grade 2 player, never busy or dark. Three levers, cheapest-first:

1. **Palette discipline (the biggest cohesion lever).** Prefer a small, shared palette across
   tiles, props, particles, and UI. Follow value-ramp discipline (SLYNYRD, §9.1): build a few
   ramps, raise brightness steadily, **drop saturation at the bright end** (no eye-burning
   neons — this matters for young eyes), and hue-shift each ramp so colors auto-harmonize. When
   authoring a new procedural tile/prop color, pick it from (or near) the existing
   `gen_tileset.py` colors rather than a fresh arbitrary RGB.
2. **A warm atmosphere wash.** A single `CanvasModulate` (a faint amber "golden-hour" tint) plus
   a subtle full-screen vignette turns the flat-lit map into a storybook scene — one node, zero
   art. Keep it *subtle*: the world should still read as bright and cheerful, not tinted heavily.
3. **Gentle motion.** A little movement makes a scene feel alive: soft drifting pollen in the
   meadow, a few fireflies near the forest/lake, a slow water shimmer on the lake. Reproduce
   these with **native Godot** (`CPUParticles2D`/`GPUParticles2D`, `Parallax2D`, a small
   `canvas_item` shader, or tweened `Polygon2D`) — never imported third-party asset packs.

**In-repo production constraint (hard).** All art must be producible inside this repo:
procedural Python (`gen_tileset.py`/`gen_sfx.py` precedent), hand-authored Godot
polygons/particles/shaders/tweens (`Pet.tscn`/`StandingStone.tscn` precedent), or the documented
AI-source normalization pipeline (`ASSET_NORMALIZATION_PIPELINE.md`). No CraftPix/itch/store
packs — they add license risk and break the placeholder-art-first posture.

**Keep it gentle (kid audience).** Per `NORTH_STAR.md` and `RESEARCH_NOTES.md` §7.1: atmosphere
and juice stay soft — subtle tints, few particles, no heavy screen shake or harsh flashes.

## Asset acceptance checklist

Before using an asset in a scene:

- [ ] file name uses `snake_case`
- [ ] transparent PNG unless intentionally otherwise
- [ ] correct target size
- [ ] readable in Godot at game scale
- [ ] source prompt or origin saved when applicable
- [ ] `.import` files committed if Godot generates them
