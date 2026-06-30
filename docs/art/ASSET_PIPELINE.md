# Asset Pipeline

This document defines the first lightweight art workflow for Eldoria-Godot. It is intentionally small so we can add real art without cluttering the project.

## Folder layout

Game-ready assets go in `assets/sprites/` by gameplay category:

- `assets/sprites/characters/`
- `assets/sprites/npcs/`
- `assets/sprites/items/`
- `assets/sprites/terrain/`
- `assets/sprites/buildings/`
- `assets/sprites/ui/`

Source/reference material goes in `assets/source/`:

- `assets/source/prompts/`
- `assets/source/references/`
- `assets/source/generated/<asset_id>/` — raw AI-generated source sheets, before normalization

Manifests for the normalization pipeline (see below) go in `assets/manifests/`.

The `assets/source/` and `assets/manifests/` trees contain `.gdignore` files so Godot does
not import prompts, reference material, or manifests as game assets.

## Normalizing AI-generated source art

Raw ChatGPT/Gemini output is source art, not a final asset — it needs resizing,
background cleanup, and exact dimensions before it belongs in `assets/sprites/`. That
workflow (the manifest format, the `normalize`/`validate` commands, naming, and the
8-direction/mirroring and armor-layering conventions) is documented in
[`ASSET_NORMALIZATION_PIPELINE.md`](ASSET_NORMALIZATION_PIPELINE.md).

## Naming rules

Use `snake_case` for files and folders.

Examples:

- `elder_rowan_idle.png`
- `mira_gardener_idle.png`
- `golden_star.png`
- `glowing_herb.png`
- `village_grass_tile.png`

Use clear prefixes when assets are related:

- `hero_mage_down.png`
- `hero_mage_walk_4x4.png`
- `npc_mira_idle.png`
- `item_glowing_herb.png`

## Target sizes

Starting targets:

- Characters/NPCs: 32x32 or 32x48
- Items/icons: 16x16 or 32x32
- Terrain tiles: 16x16 or 32x32
- Buildings: multiples of tile size, commonly 64x64, 96x96, or 128x96
- UI icons: 32x32

Keep dimensions consistent within a category.

## Source vs exported assets

Keep source prompts, references, and editable files separate from game-ready PNGs.

- Source prompts: `assets/source/prompts/`
- Reference images or notes: `assets/source/references/`
- Godot-ready transparent PNGs: `assets/sprites/...`

Generated images should be cleaned and exported into the appropriate `assets/sprites/` folder before they are used in scenes.

## Godot import hygiene

Track Godot-generated metadata when Godot creates it:

- `.import` files for imported images
- `.uid` files for scripts/resources/scenes when generated

Do not manually edit `.import` files unless needed.

## Magenta background rule

Magenta backgrounds are acceptable during image-generation workflows, but final Godot sprites should normally be transparent PNGs. Only use magenta in-game when intentionally testing transparency cleanup.

## PR rules for art

Art PRs should stay small:

- one NPC sprite set, or
- one item/icon set, or
- one terrain/building slice, or
- one UI icon set.

Each art PR should explain:

- source prompt or origin
- intended use
- dimensions
- whether files are placeholders or production candidates
- manual Godot validation performed
