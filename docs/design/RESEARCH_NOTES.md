# Research Notes

Five deep-research documents were produced by other AI tools (ChatGPT/Gemini/Codex deep
research) and reviewed critically when re-onboarding Claude to this project. They live in
the user's `~/Downloads`, not the repo. This file captures **what each is good for, what to
ignore, and why**, so the provenance and caveats aren't lost.

General caveat: all five are AI-generated "deep research." Treat them as well-sourced
starting points, not authority. Several cite plausible-but-unverified specifics (named
plugins, benchmark numbers, "Project Aeternum"). Verify before depending on a specific
claim.

## 1. Curriculum-Aligned Design Guide (PDF) — **the keeper**

*"Eldoria-V2 Design Guide for a Beautiful, Deep, Addictive, Immersive, Curriculum-Aligned
2D RPG."*

The most valuable and most Eldoria-specific. Evidence-based, with real sources (Sea of
Stars, Octopath II, CrossCode, Children of Morta; NN/g kids-UX; stealth-assessment
literature; Alberta curriculum).

- **Use:** the whole design spine — cohesive single vertical slice; quests as playable
  learning arcs; two age profiles (6–8 / 9–12); layered moment/session/meta loops;
  stealth/evidence-centered assessment; parental controls; accessibility defaults; ESRB
  E10+/COPPA safety. This drives `NORTH_STAR.md` and `CURRICULUM_MAP.md`.
- **Caveat:** subjects and exact Alberta outcome codes are intentionally unspecified — the
  user must pin them (tracked as `TODO` in `CURRICULUM_MAP.md`).

## 2. Claude — AI Coding in Godot (.docx) — **mine selectively**

*"AI-Powered Godot 2D RPG Development — A Reference Guide."* The strongest of the AI-coding
docs; modern and concrete.

- **Use:** the `CLAUDE.md` skeleton and GDScript conventions (typed vars, member ordering,
  snake_case files / PascalCase `class_name`, signals over polling); the asset
  normalization / palette-lock idea (Pyxelate); the "polish shader shortlist" (white-flash
  on hit, outline, dissolve, palette swap, water, chromatic aberration) for later.
- **Ignore for now:** its full data-driven architecture (EventBus + StateManager +
  SceneManager + RegistryManager + SaveManager, everything in `.tres`). That is heavier
  than this project wants — it conflicts with the deliberate one-autoload minimalism. Adopt
  pieces only when content justifies them.

## 3. Visual Design Guide V2 (PDF) — **cheap parts now, heavy parts later**

*"Executable 2D RPG Visual Design Guide for Eldoria V2."* A rigorous art/asset/animation
"production contract."

- **Use:** the cheap-to-lock technical decisions — 640×360, 16×16 grid, 32×48 actors,
  palette discipline, nearest import, naming, frame counts. Captured in `VISUAL_CONTRACT.md`.
- **Ignore for now:** atlas families, JSON metadata sidecars, asset/palette/animation
  registries, skeletal rigs — premature for a placeholder-polygon project.
- **Caveats:** it openly states it never saw the real Eldoria-V2 art style and *assumes*
  pixel-art/top-down; it is Unity-leaning (its only code sample is Unity C#). Useful rules,
  wrong default engine framing.

## 4. ChatGPT — AI Coding in Godot (.docx) — **low novelty**

*"AI-Assisted 2D RPG Game Development in Godot: A Comprehensive Guide."* A competent but
generic primer (version drift Godot 3 vs 4, prompt decomposition, signals/composition,
asset normalization).

- **Use:** fine as onboarding for someone new to AI-in-Godot.
- **Ignore:** nothing Eldoria-specific; mostly already practiced here.

## 5. Building a Family 2D RPG (PDF) — **process & safety**

*"Building a Family 2D RPG With Claude Code, OpenAI Codex, and Google AI Pro."*

- **Use:** multi-tool workflow (Claude as lead architect, Codex as parallel worker/reviewer,
  Gemini big-context reviewer); plan-mode-first habit; family-safety and licensing/release
  notes (CC0/commercial-only assets, itch.io, Google Play $25 fee, adult-operated 18+
  accounts). Relevant since the project is built across several AI tools.
- **Ignore:** engine debates (Godot already chosen) and overlap with docs #2/#4.

## Cross-cutting takeaway

Two camps: the AI-coding + visual guides push toward **more architecture and heavier
pipelines**; the curriculum guide and this project's own philosophy push toward **cohesion
and minimal scope**. Eldoria-Godot stays in the minimalist camp: let the curriculum guide
drive *what* to build, take only the cheap-to-lock technical decisions from the rest, and
defer heavyweight architecture/asset systems until real content demands them.

## 6. Live web research for the post-gear/shop/pets backlog pass (2026-07-01)

Added by `game-architect` while planning the slices that follow PR #35 (M3 gear/shop) and
PR #36 (M4 pets). General caveat from above still applies — these are web sources, not
Eldoria-specific authority; each is used only where it matches this project's existing
minimalist, bonus-only, placeholder-art-first posture.

### 6.1 Loot tables, rarity tiers, and fairness

- ["Loot Drop Rates Calculation Guide: Numbers to Feel" — PulseGeek](https://pulsegeek.com/articles/loot-drop-rates-calculation-guide-numbers-to-feel/) —
  drop tables are commonly balanced backwards from a target *items-per-hour-of-play* rate,
  not forwards from an arbitrary percentage; top-rarity drops are conventionally kept to a
  low single-digit percent per roll so they stay special without starving the player, and
  perceived fairness is a UX/presentation problem as much as a math one (players overweight
  recent streaks, so framing/messaging around a drop matters).
- ["Defining Loot Tables in ARPG Game Design" — Game Developer](https://www.gamedeveloper.com/design/defining-loot-tables-in-arpg-game-design) —
  professional loot tables are usually tuned per-source (a specific enemy or chest), not one
  global table, and rarity bands are typically bucketed (common/uncommon/rare/…) with each
  band mapped to a concrete in-game effect so a rarity tag always *means* something
  consistent.
- **Use for this project:** M3's 3-rarity ladder (Common/Uncommon/Rare, `docs/design/
  GEAR_AND_ECONOMY.md`) already matches the "bucketed, meaningful rarity" pattern — extend
  it, don't invent a new scheme. The "per-source table, not one global pool" idea directly
  informs tying specific rarities to specific enemies (a stronger monster should have a
  chance at a better bucket) rather than a flat drop rate for every enemy. Because the
  audience is Grade 2/5, keep any randomness *additive only* (a chance at a **bonus** drop on
  top of the existing guaranteed 1-coin drop), never a chance of *no* reward, so a young
  player is never disappointed by an empty-handed kill — this also satisfies the
  curriculum's bonus-only, non-punitive rule by analogy.

### 6.2 Shop economy — faucets, sinks, and pacing

- ["Value chains — A method for creating and balancing faucet-and-drain game economies" —
  Lost Garden](https://lostgarden.com/2021/12/12/value-chains/) and ["The Principles of
  Building A Game Economy" — Department of Play](https://departmentofplay.net/the-principles-of-building-a-game-economy/) —
  a healthy economy needs both faucets (where currency enters: kills, quests) and sinks
  (where it leaves: shop purchases, upgrades); for **fixed-length** games (explicitly called
  out as the shape kids' games often take) the recommended technique is to tally all fixed
  sinks in a spreadsheet first, then size faucets to match, rather than tuning faucets first
  and hoping sinks catch up.
- [Gold sink — Wikipedia](https://en.wikipedia.org/wiki/Gold_sink) — the "pinch point" is
  the balance point where currency is scarce enough to feel valuable but not so scarce that
  earning it feels like a grind; overshooting toward scarcity is the classic way a shop
  economy becomes punishing for a young/casual audience.
- **Use for this project:** M3 already ships one faucet (1 coin per Meadow Slime) and one
  sink (3 weapons, 3/8/20 coin prices). The natural next economy slice is widening the
  **faucet** side slightly (a second, still-tiny coin source) or adding a **restock/repeat
  sink** so coins earned after the last weapon is bought still feel purposeful — both read
  as small, additive slices rather than a system rework, and both must keep prices low
  enough that a Grade 2 player reaches the top item within a normal session (avoiding the
  "grindy economy" failure mode this source flags).

### 6.3 Enemy variety and a first mini-boss

- ["Building Better Bosses" — Game Developer](https://www.gamedeveloper.com/design/building-better-bosses) and ["Boss Design: How to Make an Unforgettable Boss Battle" —
  Game Design Skills](https://gamedesignskills.com/game-design/game-boss-design/) — a core
  fairness rule is that every dangerous move must be **clearly telegraphed** (a wind-up
  animation, a visual/audio tell) far enough ahead that a player can learn to read and react
  to it, not just react to already having been hit; a first encounter with a new enemy type
  should function as a **loose tutorial** for its tell, not spring the mechanic at full
  difficulty.
- ["Encounter" — The Level Design Book](https://book.leveldesignbook.com/process/combat/encounter) —
  mini-bosses conventionally land at a **mid-point** of a zone/arc as a small climax, and are
  most simply built as a tougher variant of an enemy the player already knows (bigger
  health/damage numbers, one added telegraphed move) rather than a wholly new creature or a
  bespoke boss-fight system.
- **Use for this project:** this argues strongly for the smallest possible mini-boss slice —
  a **larger, tougher Meadow Slime variant** ("Elder Slime" or similar) reusing the existing
  `MeadowSlime.gd`/component architecture almost unmodified (more HP, a single new
  telegraphed contact-damage windup made visible before it hits), rather than a new enemy
  archetype or any bespoke boss-UI/phase system. This satisfies "resist feature equity" by
  deepening the existing Meadow Slime system instead of adding a parallel monster type, and
  keeps within the "no full boss-fight system" constraint from this task's brief.

### 6.4 Readable map/biome layout

- ["Best Practices for Game Map Layout: Flow, Landmarks & Player Navigation" — Sandboxr](https://sandboxr.com/best-practices-for-game-map-layout-flow-landmarks-player-navigation/) —
  effective layouts work at macro/meso/micro scales, and progression is best gated with
  **soft, diegetic blockades** (terrain, a lake, a rock outcrop — exactly what M1's zone
  already uses) rather than invisible walls; a good readability playtest is whether a player
  can navigate using world cues alone, with the minimap/UI off.
- ["Wayfinding" — The Level Design Book](https://book.leveldesignbook.com/process/blockout/wayfinding) —
  distinctive **landmarks** placed along a path (and re-shown after a distraction like a
  fight or a cave section) let players re-orient themselves without a map; a landmark
  visible from far away ("weenie") sets a directional goal before the player commits to
  walking there.
- **Use for this project:** M1's zone already has a lake and two rock outcrops as impassible
  soft-gates, but the 4 NPCs currently have no long-range visual landmark pulling the player
  toward them (the source's core failure mode — a layout that only reads correctly once
  you're already standing in it). The smallest next slice here is a **readability pass**,
  not a new biome: add 1-2 tall/bright landmark props (e.g. a distinctive tree or standing
  stone) near the existing path forks so a player can see where to go from a distance,
  satisfying "cohesion over volume" (deepen the existing single zone) over a whole new biome.

### General caveat (applies to §6 as elsewhere)

These are web-search summaries of secondary sources, not primary game-design texts read in
full; treat specifics (e.g. exact drop-rate percentages) as illustrative ranges to tune
in-engine, not numbers to hardcode without playtesting.
