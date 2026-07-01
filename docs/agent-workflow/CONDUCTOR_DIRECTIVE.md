# Conductor Directive (2026-07-01)

Standing orders for every AI tool working this repo (Claude, Codex, Antigravity, and the
`.claude/agents/` subagent suite). Written after a full repo audit. Read `AGENTS.md` and
`docs/design/NORTH_STAR.md` first; this file tells you **what to build next and in what
order**, and the process rules that keep parallel agents from colliding.

## Audit snapshot

- `main` ends at #38 (backlog v1). Suite on main: **16/16 green** via
  `Godot --headless --path . res://tests/TestRunner.tscn`.
- Six mergeable PRs are queued: #39 (slime coin drop, verified 17/17), #40 (Legendary
  Dawnbringer Blade), #41 (landmark props), #42 (backlog refill v2 + research §7),
  #43 (hit-flash juice), #44 (HUD coin counter). All were headless-tested AND
  live-gameplay-tested before opening.
- #36 (M4 pets) is **orphaned**: it targets the already-squash-merged
  `m3-gear-economy-shop` branch. Decision: **close #36 and rebuild pets fresh** from the
  approved design below once the queue merges. Do not try to rebase it.
- The game has **zero audio** — no AudioStreamPlayer nodes, no sound assets. This is now a
  first-class priority (see build order).

## Merge queue (human merges; agents never merge)

Recommended order: **#39 → #42 → #40 → #41 → #43 → #44**, then close #36.
Only expected conflict: #39 and #40 both append to `tests/game_state_tests.gd` and
`docs/design/GEAR_AND_ECONOMY.md` — both purely additive, keep both sides.

## Build order after the queue merges

Priorities chosen for maximum kid-delight per unit of risk, honoring NORTH_STAR
("cohesion over volume", bonus-only/non-punitive learning, resist feature equity).

1. **P0 — Sound pass v1.** The game is silent. Add a handful of gentle SFX (sword swish,
   slime hit "boing", coin pickup chime, quest-complete fanfare, UI click) via
   AudioStreamPlayer/AudioStreamPlayer2D, plus one looping ambient/meadow track at low
   volume. Source: CC0 packs (Kenney.nl audio is the default choice — same source family
   as prior art norms) checked into `assets/audio/` with attribution noted in the PR.
   Keep volumes soft; audience is 7–11.
2. **P0 — M4 pets** (design locked, user-approved; summary below). The single biggest
   "wow" for the kids.
3. **P1 — "Creatures met" codex** (backlog slice, needs #39's MeadowSlime.gd).
4. **P1 — Gentle repeatable coin faucet** (backlog slice, needs #41's Main.tscn; fixes
   the real economy bottleneck of 3 non-respawning slimes).
5. **P2 — Elder Slime mini-boss** (backlog slice, needs #39).
6. **P2 — Real-art pass** replacing placeholder polygons (landmarks, coin, pet) via the
   asset pipeline + `asset-normalizer`, honoring `docs/design/VISUAL_CONTRACT.md`.
7. **P3 — Second biome scaffold** (new zone + transition) — only after the above; refill
   the backlog via game-architect research first.

## M4 pets — locked design (rebuild fresh, do not resurrect #36)

- Unlock: completing all 4 village quests (same gate as the Tier 1 armor grant in
  `GameState._check_and_grant_tier1_armor()`); auto-equip on grant so the reward is felt.
- One pet species to start, placeholder art first. Follow-only AI (CharacterBody2D,
  move toward player when > 24px away, speed ~220 > player 160, y-sorted). No pet combat.
- Data shape mirrors gear: `PetDefinition` resource (`id`, `label`, `rarity`, `hp_bonus`),
  `owned_pets: Array[String]` + `equipped_pet: String` in GameState, `pet_changed`/
  `pet_unlocked` signals, `get_effective_max_hp()` composing the bonus, SAVE_VERSION 3.
- Character panel gets a Pets section (equip/unequip rows, stat lines, same dynamic-list
  pattern as the M3 weapons list). HUD `_ready()` must read `get_effective_max_hp()`,
  not the raw `PLAYER_MAX_HP` constant.
- Spawn/despawn wired from `Player.gd` on `pet_changed` (same sibling-add pattern as
  `MeadowSlime._spawn_coin_drop()`).
- Full verification: headless suite extended (~19–20 tests) AND a live playtest of the
  unlock → follow → unequip/re-equip → save/reload loop.

## Process rules (non-negotiable, learned the hard way this run)

1. **One slice per PR, branched directly off `origin/main`**
   (`git checkout -b <slice> origin/main`). Never stash/pop, never `reset --hard` (the
   local `project.godot` carries uncommitted godot-ai MCP lines; stage with
   `git add -A -- ':!project.godot'`).
2. **Never stack on an unmerged PR.** This repo squash-merges; stacks get orphaned
   (that is exactly what killed #36). If a slice needs an unmerged PR's files, it is
   blocked — pick a disjoint slice or stop and say so.
3. **Green means the headless suite actually ran locally and passed.** Static review is
   not a pass. Additionally, every gameplay-visible slice gets a live playtest (godot-ai
   MCP `project_run` + input/eval/screenshot) before the PR opens.
4. **New tests go in new isolated files** registered in `tests/test_runner.gd`
   (one-line hotspot) instead of appending to `tests/game_state_tests.gd`
   (the recurring merge hotspot). `tests/hit_flash_tests.gd` (#43) is the model.
5. **Doc updates edit fresh regions** of `docs/CURRENT_STATE.md` / the backlog; never
   rewrite shared lines (e.g. the "N tests" count) that other open PRs also touch.
6. **Agents never merge and never push to `main`.** The human merges. Stop conditions:
   blocked-on-user-input, a failed test, or an unmerged dependency.
7. **Kid-safety design gates stay absolute:** learning stays bonus-only and non-punitive,
   feature equity across profiles/NPCs/biomes, no dark patterns, no grind walls, gentle
   feedback (no harsh flashes/shakes/sounds). Curriculum changes remain CONFIRM-gated
   per `EXPANSION_BACKLOG.md`.
