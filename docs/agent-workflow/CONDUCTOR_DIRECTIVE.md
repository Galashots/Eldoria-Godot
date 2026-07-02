# Conductor Directive (2026-07-01)

Standing orders for every AI tool working this repo (Claude, Codex, Antigravity, and the
`.claude/agents/` subagent suite). Read `AGENTS.md` and `docs/design/NORTH_STAR.md` first;
this file tells you **what to build next and in what order**, and the process rules that
keep parallel agents from colliding.

## Audit snapshot (updated post-#56)

- `main` now includes **PRs #45 through #56**, all merged: this conductor directive, the M4
  pets rebuild (Mossy, follow AI, panel UI, save v3), a gitlink fix, the Meadow Slime respawn
  faucet, sound pass v1 (`AudioManager` autoload + ambient/SFX), the "Creatures met" codex,
  the first mini-boss (Elder Slime), a backlog refill (v3), the boss keepsake payoff, the
  epic region-distinct map pass (220x140 tiles: village green / flower meadow / forest edge /
  lake+dock / rocky border), Yarrow's numeracy in-fiction reframe, and boss visual polish
  (Elder Slime is now gold-tinted with a crown).
- Suite on main: **55/55 green** across 9 isolated suites in `tests/test_runner.gd`, via
  `Godot --headless --path . res://tests/TestRunner.tscn`.
- The prior audit's two open risks are both resolved: #36 (orphaned M4 pets PR) was closed
  and pets were rebuilt fresh per the locked design below (now shipped); the game is no
  longer silent — `AudioManager` (sound pass v1) has shipped.
- The merge queue from the prior audit (#39–#44 plus M4/audio/codex/faucet/boss) is fully
  drained — there is no stale queue to track right now. See "Current frontier" below for
  what's in flight.

## Current frontier

Three `ready` slices from `docs/design/EXPANSION_BACKLOG.md`, sequenced to build after the
region-map pass (all reference the new map geometry or its readable regions):

1. **Discovery sparkle-spots** — hidden exploration finds scattered across the new map's
   distinct regions, reusing `Collectible`/`CoinPickup` machinery, recording a permanent
   "Places discovered" codex entry (mirroring `creatures_met`).
2. **Diegetic campfire "rest" beat** — a cozy, in-fiction session-end stopping point in the
   village hub (explicit save + a gentle fade), strictly additive/non-punitive, no FOMO.
3. **Region ambience pass** — per-region ambient sound (meadow birds, forest wind, lake
   water) cross-fading as the player crosses region boundaries, generalizing the existing
   single global `AudioManager` ambient track.

Alongside these, a fresh **art/learning research pass** is under way per the owner's mandate
("cool backgrounds, epic art, learning out the wazoo") — expect the `game-architect` to
refill `EXPANSION_BACKLOG.md` with slices drawing on that research once it lands; do not
build ahead of it speculatively.

## Build order

Priorities chosen for maximum kid-delight per unit of risk, honoring NORTH_STAR
("cohesion over volume", bonus-only/non-punitive learning, resist feature equity). The
original P0/P1/P2 list from the first audit (sound pass, M4 pets, codex, coin faucet, Elder
Slime mini-boss, real-art pass) is **fully shipped** — see the audit snapshot above. Next in
line is the "Current frontier" list above, in the order given, followed by:

- **Real-art pass** replacing remaining placeholder polygons (pet, landmarks, coin/gear
  icons) via the asset pipeline + `asset-normalizer`, honoring
  `docs/design/VISUAL_CONTRACT.md` — still open, lower priority than the frontier slices.
- **Second biome scaffold** (new zone + transition) — only after the above; refill the
  backlog via game-architect research first.

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
