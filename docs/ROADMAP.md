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
   full replacement idle sprite sets, reachable in-game via the equip system (milestone 5).
   Only idle poses exist for Tier 1 (no walk-cycle armor frames) — open follow-up work.
4. ~~Add inventory/reward foundation.~~ Done — the character panel's item list is generic
   (any `GameState.collected_items` entry, with quantity), and learning-check bonuses are
   named badges (`ContentDefinitions.BADGE_LABELS`) shown in both the completion dialogue
   and the character panel, instead of an anonymous flag/count.
5. ~~Add an equip system.~~ Done — completing all three existing quests (Elder, Mira, Finn)
   auto-equips Tier 1 (Leather) armor via `GameState.equipped_armor_tier` /
   `_check_and_grant_tier1_armor()`, `Player.gd` swaps `Body`'s `SpriteFrames` to the tier1
   set, and the character panel's equipment line shows it. No manual equip/unequip UI, no
   new quest — the simplest possible slice, per `docs/design/ARMOR_TIERS.md`. Armored
   walking is a static pose (no tier1 walk-cycle art exists yet) — an accepted limitation.
6. ~~Add local save/load.~~ Done — `GameState` autosaves to `user://savegame.json` (JSON via
   `FileAccess`/`JSON`, no custom Resource class) on every profile/quest/item/armor change
   and loads it in its own `_ready()`, before any other scene node's `_ready()` runs — so the
   game auto-resumes silently on relaunch with no "Continue vs New Game" menu, and no changes
   were needed to `ProfileSelect.gd`/`Collectible.gd`/`HUD.gd` (they already re-derive from
   `GameState` correctly). A mouse-only "Reset Progress..." button was added to the character
   panel in the same milestone, with a two-step confirm sub-view, deliberately hard for a
   Grade 2/5 player to trigger by accident.
7. ~~Add a GDScript test harness.~~ Done — a small custom headless suite (`tests/`, no
   third-party framework: `tests/TestRunner.tscn` + `tests/test_runner.gd` +
   `tests/game_state_tests.gd`) covers `GameState`'s quest lifecycle, item/quest wiring,
   badge tracking, the Tier 1 armor grant, and the save/load/reset round trip. Building it
   caught two real bugs (both fixed): `collected_items` counts silently turning into floats
   after a save/load round trip (JSON numbers always parse as float), and a signal
   connected to a **lambda** on a `RefCounted` object not reliably firing on this Godot 4.7
   build — every test probe now uses a named method instead. Run via
   `Godot...console.exe --headless --path . res://tests/TestRunner.tscn`, see
   `docs/CURRENT_STATE.md`. Now add more story/quest content on top of this tested base.
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
- **`Armor` node fate.** The hidden `Armor` `AnimatedSprite2D` (PR #23) is still unused after
  the equip system (milestone 5) shipped — that milestone deliberately used the full-body-swap
  approach on `Body` instead, per `docs/design/ARMOR_TIERS.md`. Keep it only if a future
  accessory layer (capes/masks) will use it; otherwise remove to avoid confusion.

## Architecture rules
- Every milestone must preserve the playable slice.
- Prefer tiny PRs.
- Do not introduce EventBus until signals become unmanageable.
- Resource experiment proven (see milestone 2) for item definitions specifically — do not
  migrate quest summaries or profile labels to `.tres` until there's a concrete reason to.
- Asset pipeline pass proven (see milestone 3) — production asset replacement may scale.
