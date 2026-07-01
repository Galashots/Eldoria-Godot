# Roadmap

## Current baseline
- Elder → Mira → Finn → Yarrow placeholder vertical slice.
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
8. Add more story/quest content — **in progress.** A fourth quest, Yarrow the Healer
   (`QUEST_YARROW_SILVERLEAF`), is done: gated behind Finn, mirroring the Elder/Mira/Finn
   shape exactly (fetch item, two-choice check, bonus-only completion). Deliberately narrow
   in scope — same village hub, same linear chain, same already-confirmed numeracy/literacy
   subjects — per `docs/design/NORTH_STAR.md`'s "resist feature equity across many
   NPCs/biomes" pillar and `docs/design/CURRICULUM_MAP.md`'s subject-scope CONFIRM/ADJUST
   flag, both of which argue against just repeating this pattern indefinitely. Tier 1 armor
   now requires all four quests. **Before adding a fifth quest, get user input on subject
   scope** (`CURRICULUM_MAP.md`'s "Proposed subject scope — CONFIRM/ADJUST" table is still
   unconfirmed) rather than defaulting to numeracy/literacy again.
9. Plan iPad/web playtest/export path.

## Phase 2 — from placeholder slice to a real game

The vertical slice above (4 quests, save/load, equip, tests) is done; the user has since
approved a Phase 2 roadmap toward a real game (combat, pets, bigger maps, farm/home-base,
mobile). Milestone order: **M1 world/map foundation** (done) → **M2 combat + first monster**
(done, next below) → M3 gear/rarity/inventory + shop → M4 pets → M5 bigger world &
traversal → M6 farm + home base → M7 mobile → M8 UI/theme polish. Architecture (EventBus,
component nodes, `.tres`-driven stats) is introduced feature-by-feature, not upfront. Full
plan context in project memory (`phase2-roadmap`).

10. ~~M1 — World/map foundation.~~ Done — `scenes/main/Main.tscn`'s flat `World/Floor`
    Polygon2D + single `Obstacle` replaced with a `World/Ground` `TileMapLayer` over a
    160x100-tile (2560x1600px) zone, using a bootstrap 4-tile placeholder tileset
    (`assets/sprites/tiles/placeholder_tileset.png` + `assets/tilesets/placeholder_tileset.tres`:
    grass/path walkable, water/rock impassible via `TileSet` physics-layer collision
    polygons). `World.y_sort_enabled` and per-entity `y_sort_enabled` are on. The Player's
    `Camera2D` (`scenes/player/Player.tscn`) now has `limit_left/top/right/bottom` matching
    the map bounds and `position_smoothing_enabled`. The existing 4 NPCs, 4 collectibles,
    and player spawn are repositioned into the new zone, connected by dirt paths, with a
    lake and two rock outcrops as collision obstacles to prove the system. Save-schema
    versioning was folded in per the Phase 2 plan: `GameState.save_game()` now writes a
    `"version": 1` field and `load_game()` calls a `_migrate(data)` step (currently a no-op,
    since old un-versioned saves and v1 have the same shape) — future schema growth
    (combat/inventory/pets/farm) can migrate forward instead of crashing. No EventBus/
    component architecture yet — those arrive with M2 combat, per the "grow
    feature-by-feature" decision.

11. ~~M2 — Combat + first monster.~~ Done — the component architecture arrives:
    `HealthComponent`/`HitboxComponent`/`HurtboxComponent` (`scripts/core/combat/`), matched
    by group membership rather than a dedicated physics layer (everything in this project
    still defaults to layer/mask 1, proven enough at this scale). Real-time, movable combat
    (no battle-transition screen): a new `attack` input action swings a brief hitbox in the
    player's facing direction. First monster: **Meadow Slime** (wander/chase AI, 3 hp, small
    contact damage, placeholder green-blob art — see `docs/design/MONSTER_CONCEPTS.md` for
    the real-art ChatGPT prompt). The player keeps using the existing, already-persisted
    `GameState.player_hp` rather than getting its own `HealthComponent`; death is
    non-punitive (teleport to the scene's original spawn point, heal to full, a friendly
    line — no game over screen). The user's math-question damage-multiplier idea is
    implemented as a stacking, decaying combat streak (`GameState.combat_streak` /
    `get_combat_multiplier()`, capped at 3, `1 + streak*0.5`, correct-only per the
    bonus-only rule) via a new `CombatQuestion` UI kept deliberately separate from
    `LearningCheck` (no quest coupling). No `.tres` stats resource was introduced — a single
    monster and the player's existing plain fields don't yet meet the "more content, or a
    second consumer needing structured data" promotion bar; deferred to M3 (gear modifying
    these numbers) or a second monster, whichever comes first. No EventBus yet — every new
    signal is a direct connection, same as the existing NPC-to-UI wiring. Test suite grew to
    13 (4 new, covering the combat math). Two real bugs caught live, both now structural
    fixes: a `HurtboxComponent`'s exported `HealthComponent` node reference did not reliably
    resolve from a raw `NodePath(...)` literal in `.tscn` text (fixed via sibling-name
    auto-discovery in `_ready()` instead); and setting `monitorable`/`monitoring` directly
    from inside a hit-reaction callback raised a Godot engine error, fixed via
    `set_deferred()`.

## Cleanup backlog (from the repo audit, deliberately deferred)

Low-risk tidy-ups identified during the audit but intentionally not bundled into feature
work — pick up opportunistically:

- **Mixed indentation.** `Player.gd` uses tabs; `GameState.gd`, `ContentDefinitions.gd`,
  `CharacterPanel.gd`, `LearningCheck.gd` use spaces. Godot's style guide is tabs. Harmless
  (GDScript tolerates either per-file) but complicates diffs/`script_patch`.
- ~~**Orphaned proof asset.**~~ Done — `hero_body_idle_s.*` (manifest + source + sprite +
  `.import`) deleted; it was the one-off pipeline proof render, referenced by no scene/script.
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
