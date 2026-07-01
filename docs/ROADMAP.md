# Roadmap

## Current baseline
- Elder → Mira → Finn placeholder vertical slice.
- Two child profiles: Grade 2 Mage and Grade 5 Adventurer.
- Local-first, single-player, no accounts, no analytics, no ads.
- Placeholder art-first.
- `ContentDefinitions.gd` currently owns lightweight display text.

## Near milestones
1. Keep current-state docs truthful after each merge.
2. ~~Run a tiny Resource experiment for quest/item definitions.~~ Done — item display
   labels are now `ItemDefinition` `.tres` resources under `data/items/`; quest summaries
   and profile labels stay as dictionaries in `ContentDefinitions.gd` for now.
3. Run the first real *production* asset replacement pass — the pipeline pass is proven
   (one test sprite went source -> manifest -> normalize -> validate -> `Player.tscn` and
   runs cleanly), so this is now about generating approved hero/armor art, not the tool.
   See `docs/art/ASSET_NORMALIZATION_PIPELINE.md`. Both Grade 2 Mage and Grade 5
   Adventurer now have production art with 8-direction movement-facing, walk-cycle
   animation, and Tier 1 (Leather) armor art (`docs/design/ARMOR_TIERS.md`) normalized as
   full replacement idle sprite sets. No equip/inventory system exists yet to grant or wear
   that armor in-game, and only idle poses exist for Tier 1 (no walk-cycle armor frames) —
   both are open follow-up work, not yet scheduled as their own milestone here.
4. ~~Add inventory/reward foundation.~~ Done — the character panel's item list is generic
   (any `GameState.collected_items` entry, with quantity), and learning-check bonuses are
   named badges (`ContentDefinitions.BADGE_LABELS`) shown in both the completion dialogue
   and the character panel, instead of an anonymous flag/count.
5. **Equip system (next active milestone).** Make the already-generated Tier 1 (Leather)
   armor art reachable in-game — right now the art exists but nothing grants, equips, or
   renders it. Minimal loop: add `equipped_armor` state + an `equip_armor()` path to
   `GameState`, a way to *earn* leather (simplest: completing a quest / earning a badge
   grants it), swap `Body`'s per-profile `SpriteFrames` to a tier-1 variant in `Player.gd`
   (reusing `_build_sprite_frames`), and replace the character panel's "Equipment: coming
   soon" line with the equipped item. Known limitation to decide up front: Tier 1 has
   **idle poses only** (no walk frames), so armored walking either falls back to armored-idle
   (ship this first, zero new art) or needs `tier1_walk1/walk2` art generated as a follow-up.
6. Add local save/load. `GameState` is entirely in-memory today; nothing survives a restart.
7. Add more story/quest content. Slot a small headless GDScript test harness for
   `GameState`'s quest state machine in *before* this, so growing quest logic lands on a
   tested base (today only the Python pipeline has tests; game logic is manual-checklist only).
8. Plan iPad/web playtest/export path.

## Cleanup backlog (from the repo audit, deliberately deferred)

Low-risk tidy-ups identified during the audit but intentionally not bundled into feature
work — pick up opportunistically:

- **Mixed indentation.** `Player.gd` uses tabs; `GameState.gd`, `ContentDefinitions.gd`,
  `CharacterPanel.gd`, `LearningCheck.gd` use spaces. Godot's style guide is tabs. Harmless
  (GDScript tolerates either per-file) but complicates diffs/`script_patch`.
- **Orphaned proof asset.** `hero_body_idle_s.*` (manifest + source + sprite + `.import`) is
  the one-off pipeline proof render, referenced by no scene/script and explicitly not
  production art — safe to delete.
- **`Armor` node fate.** The hidden `Armor` `AnimatedSprite2D` (PR #23) is unused, and the
  Tier 1 full-body-swap decision means it won't carry body armor after all. Keep it only if a
  future accessory layer (capes/masks) will use it; otherwise remove to avoid confusion. The
  equip milestone above is the natural point to decide.

## Architecture rules
- Every milestone must preserve the playable slice.
- Prefer tiny PRs.
- Do not introduce EventBus until signals become unmanageable.
- Resource experiment proven (see milestone 2) for item definitions specifically — do not
  migrate quest summaries or profile labels to `.tres` until there's a concrete reason to.
- Asset pipeline pass proven (see milestone 3) — production asset replacement may scale.
