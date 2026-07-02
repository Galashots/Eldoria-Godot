# Expansion Backlog

The autonomous-expansion queue. **Owned and maintained by the `game-architect` subagent**
(see `.claude/agents/`), which researches 2D-RPG design and refills this file with small,
buildable vertical slices. The orchestrator session builds the top `ready` slice, then loops.

This backlog serves `docs/design/NORTH_STAR.md`. Every slice must deepen the cohesive vertical
slice, honor the **"resist feature equity across many NPCs/biomes"** pillar (make existing
systems pay off before adding parallel ones), and keep any learning **bonus-only and
non-punitive** (`docs/design/CURRICULUM_MAP.md`). Slices must respect all `AGENTS.md`
boundaries (Godot 4.x + GDScript, single-player local-first, no accounts/analytics/ads/APIs/
cloud, no full V2 port, placeholder-art-first).

## Per-slice schema

Every entry MUST include all of these fields:

- **Title** — short, imperative.
- **Goal** — one or two sentences: what the player gets.
- **Design rationale** — tie to a specific NORTH_STAR pillar AND a cited research finding
  (source recorded in `docs/design/RESEARCH_NOTES.md`).
- **Acceptance criteria** — concrete, checkable bullets defining "done".
- **Likely files touched** — a short scoping list.
- **Curriculum tie-in** — how it maps onto `CURRICULUM_MAP.md`, or "none — pure systems".
- **Status** — `ready`, `blocked: <reason>`, or `done`.

### Template (copy for each new slice)

```
### <Title>
- **Goal:**
- **Design rationale:** (NORTH_STAR pillar: … | research: <title + URL in RESEARCH_NOTES.md>)
- **Acceptance criteria:**
  - [ ] …
- **Likely files touched:**
- **Curriculum tie-in:**
- **Status:** ready | blocked: <reason> | done
```

## CONFIRM-required gate

The `game-architect` must NOT unilaterally decide anything the design docs mark as needing
user input. The known open one: `docs/design/CURRICULUM_MAP.md`'s "Proposed subject scope —
CONFIRM/ADJUST" table is **unconfirmed**, so any slice that would introduce a 5th quest or a
new subject must be filed `blocked: needs-user-input` with a precise question — not built. The
orchestrator HALTS the loop when the top item is `blocked: needs-user-input`.

## Planning baseline for this pass (2026-07-01)

This pass is planned strictly **after** two in-flight PRs, treated as ground truth even
though not yet merged to `main`:

- **PR #35 (M3: gear, rarity, coins & shop)** — `GearDefinition.gd` + 3 weapons
  (`data/gear/`: Worn Dagger/Iron Sword/Oakheart Blade, Common/Uncommon/Rare), Meadow Slimes
  drop 1 coin on death, a single `Merchant`/`ShopUI`, manual equip via the character panel,
  save schema v2. See `docs/design/GEAR_AND_ECONOMY.md` (present on that branch).
- **PR #36 (M4: pets, stacked on #35)** — `PetDefinition.gd` + Mossy the Sprite (Rare, +2 Max
  HP), same all-4-quests auto-equip gate as Tier 1 armor, follow-only (no combat), save
  schema v3. See `docs/design/PETS.md` (present on that branch).

Every slice below assumes both have landed. None of them re-propose anything those PRs
already deliver or explicitly defer (sell-back, multi-slot loadouts, consumables, a second
pet species, pet combat, real icon/pet art, gear stat axes beyond `damage_bonus` — all still
out of scope until a future pass has a concrete reason to revisit them).

---

## Ready

<!-- Second expansion pass (orchestrator refill, 2026-07-01). The three slices below were
     added after the first cycles shipped (Legendary weapon = PR #40, landmark props = PR #41,
     bonus-coin drop = PR #39). They are ordered best-next-first AND by how conflict-free they
     are against that still-open PR stack; each carries a "Sequencing" note. The four original
     slices further down keep their status; PRs #39/#40/#41 flip three of them to done on merge. -->

### "Creatures met" codex: permanent world-knowledge from combat
- **Goal:** The first time the player defeats each monster type, it's recorded and shown as a
  friendly "Creatures met" entry (name + one-line factoid) in the character panel — so combat
  leaves behind permanent, collectible world-knowledge, not just coins.
- **Design rationale:** NORTH_STAR pillar 5 "every short session yields permanent progress
  (world knowledge, a keepsake, a codex entry)" | research: `RESEARCH_NOTES.md` §7.3 — a
  bestiary/compendium filled by defeating creatures is a classic low-cost collection loop, each
  entry paired with a short friendly factoid; bonus-only and non-punitive by construction (you
  only ever gain entries).
- **Acceptance criteria:**
  - [ ] `GameState` tracks a persisted set of defeated monster type ids (survives save/load and
        clears on reset), with a `record_creature_defeated(id)` that is idempotent.
  - [ ] The Meadow Slime records itself as defeated on death (one call from its death path).
  - [ ] The character panel shows a "Creatures met" section listing each recorded creature's
        label + a one-line friendly factoid (text-only, no new art).
  - [ ] Bonus-only: no gameplay/difficulty change; you cannot lose a codex entry.
  - [ ] Covered by an **isolated new test file** (registered in `test_runner.gd`), not by
        appending to `game_state_tests.gd`.
- **Likely files touched:** `scripts/core/GameState.gd`, `scripts/enemies/MeadowSlime.gd` (one
  line on death), `scripts/ui/CharacterPanel.gd` (+`.tscn`), a small factoid source, new
  `tests/codex_tests.gd` + `tests/test_runner.gd`.
- **Curriculum tie-in:** none directly — but the codex is the natural home for later "mastery
  marks" (`CURRICULUM_MAP.md`'s stealth-assessment bridge) if that's ever built.
- **Sequencing:** **wait for PR #39 to merge** — the one-line defeat hook is in
  `MeadowSlime.gd`, which #39 edits; build after #39 lands to avoid a conflict. (`GameState.gd`
  and `CharacterPanel.gd` are otherwise free.)
- **Status:** done — shipped on `slice-creature-codex`: `GameState.creatures_met`
  (Dictionary, save-schema-compatible via `.get()` default) + `record_creature_met(id)`
  (idempotent, `creature_met` signal fires once) + `has_met_creature(id)`;
  `MeadowSlime._on_died()` records `meadow_slime`; `ContentDefinitions.CREATURE_FACTS`
  (plain dictionary, one entry) backs a new "Creatures met" section in `CharacterPanel`;
  4 new tests in `tests/codex_tests.gd`.

### First mini-boss: Elder Slime (tougher Meadow Slime variant)
- **Goal:** Give the player one clearly-telegraphed, higher-stakes (but still non-punitive)
  fight — a larger, tougher Meadow Slime variant with more HP and a single new telegraphed
  windup move — without building a bespoke boss-fight system.
- **Design rationale:** NORTH_STAR pillar "Cohesion over volume" (reuses/deepens the
  existing Meadow Slime component architecture rather than adding a new enemy archetype) |
  research: "Building Better Bosses" and "Boss Design: How to Make an Unforgettable Boss
  Battle" (Game Developer / Game Design Skills), and "Encounter" (The Level Design Book),
  `docs/design/RESEARCH_NOTES.md` §6.3 — mini-bosses are conventionally a tougher variant of
  a known enemy at a zone's mid-point, and fairness requires every dangerous move be clearly
  telegraphed well before it lands, functioning as a loose tutorial for the tell.
- **Acceptance criteria:**
  - [ ] Reuses `scripts/enemies/MeadowSlime.gd`'s existing FSM/components (`HealthComponent`,
        `HitboxComponent`/`HurtboxComponent`) — implemented as a variant (exported stat
        overrides, e.g. via a scene inheriting `MeadowSlime.tscn`, or a small subclass), not
        a new parallel monster script from scratch.
  - [ ] Has meaningfully more HP than a regular Meadow Slime (tuned in-engine, not just "3x"
        blindly) and deals contact damage the same way — same non-punitive death rule
        applies (teleport/heal/friendly line, no game-over).
  - [ ] Adds exactly one new telegraphed move: a brief, clearly visible wind-up (e.g. a
        color-flash or a brief pause-then-lunge) before any bigger hit, giving the player a
        fair visual cue to react to, honoring the telegraphing research above.
  - [ ] Placed once, at a clear mid-point of the existing M1 zone (not guarding a new area),
        reusing existing placeholder art techniques (e.g. a scaled-up/recolored variant of
        the existing `meadow_slime_idle.png`, consistent with `docs/design/
        MONSTER_CONCEPTS.md`'s "placeholder-first" precedent) rather than requiring new
        production art before the system is proven.
  - [ ] No new UI system (health bar, phase indicator) is required to ship this slice — the
        existing HP/combat feedback the player already has (HUD "On Fire!"/HP readout) is
        sufficient for a first pass; a boss health bar is explicitly deferred, not part of
        this slice's acceptance criteria.
  - [ ] Test suite covers the variant's stat overrides and telegraphed-hit timing at the same
        pure-logic level M2's combat tests already do.
- **Likely files touched:** `scripts/enemies/MeadowSlime.gd` (variant hook or a small new
  subclass), `scenes/enemies/` (new scene, e.g. `ElderSlime.tscn`), `scenes/main/Main.tscn`
  (one placement), `docs/design/MONSTER_CONCEPTS.md` (append the variant), `tests/`.
- **Curriculum tie-in:** none — pure systems.
- **Status:** ready

## Blocked

### Fifth quest / new curriculum subject
- **Goal:** (not authored — see question below; do not decide this unilaterally.)
- **Design rationale:** N/A until user input resolves the open CONFIRM gate.
- **Acceptance criteria:** N/A.
- **Likely files touched:** N/A.
- **Curriculum tie-in:** Directly blocked by `docs/design/CURRICULUM_MAP.md`'s "Proposed
  subject scope — CONFIRM/ADJUST" table, which is still unconfirmed.
- **Status:** blocked: needs-user-input
- **Exact question for the user:** `CURRICULUM_MAP.md` proposes Grade 2 = numeracy primary /
  literacy secondary / science-social later, and Grade 5 = numeracy primary / literacy
  secondary / science-social later — with exact Alberta curriculum outcome codes still
  `TODO`. Before any 5th quest (or any new subject folded into an existing quest) is
  designed: **do you confirm this subject scope as-is, or do you want to adjust which
  subject comes next (e.g. move to science/social studies instead of a 3rd numeracy/literacy
  quest), and can you supply (or approve deferring) the specific Alberta outcome codes this
  table marks as TODO?**

---

## Done

### Tie loot rarity to specific enemies (Meadow Slime bonus-chance drop)
- **Goal:** Give the player an occasional *bonus* chance at coins (or, later, a rarity
  token) on top of Meadow Slime's existing guaranteed 1-coin drop, so combat and the M3 shop
  loop start to reinforce each other instead of the coin drop being a flat, un-tunable
  constant.
- **Design rationale:** NORTH_STAR pillar "Cohesion over volume" — deepens the existing
  Meadow-Slime-to-shop loop rather than adding a parallel system | research: "Loot Drop Rates
  Calculation Guide: Numbers to Feel" (PulseGeek) and "Defining Loot Tables in ARPG Game
  Design" (Game Developer), `docs/design/RESEARCH_NOTES.md` §6.1 — professional loot tables
  are tuned per-source, not as one flat global rate, and are additive-only here per the
  bonus-only rule (never a chance of *zero* reward, only a chance of *extra*).
- **Acceptance criteria:**
  - [x] Meadow Slime still always drops its existing guaranteed 1 coin (no regression).
  - [x] A small, tunable chance (e.g. ~10-15%, tuned in-engine per the research caveat, not
        hardcoded blindly) adds one *additional* coin on top of the guaranteed drop — never
        removes or reduces the guaranteed drop.
  - [x] The bonus-coin roll is implemented as a single exported probability on
        `MeadowSlime.gd` (or a tiny shared helper if a second enemy will reuse it soon), not
        a new generic loot-table framework — keep it proportional to one monster.
  - [x] Test suite covers the roll deterministically (e.g. by seeding/mocking randomness or
        asserting the guaranteed-coin path is unaffected when the bonus roll fails/succeeds).
  - [x] No visual/UI change required beyond the existing coin-drop pickup already shipped in
        M3; a second `CoinPickup` instance is an acceptable minimal presentation.
- **Likely files touched:** `scripts/enemies/MeadowSlime.gd`, `tests/game_state_tests.gd` (or
  a new enemy test file if one exists after M2/M3 land), `docs/design/GEAR_AND_ECONOMY.md`
  (append the bonus-drop rule to keep it authoritative).
- **Curriculum tie-in:** none — pure systems.
- **Status:** done — shipped on `claude/meadow-slime-coin-drop-od4ghp`: `MeadowSlime.gd`
  gained an exported `bonus_coin_chance` (default 0.12) and a pure
  `rolls_bonus_coin(chance, roll)` static function covered by a new deterministic test;
  `docs/design/GEAR_AND_ECONOMY.md` documents the additive-only "Bonus drop rule".

- **Map readability pass: landmark props near existing path forks** → shipped two distinct
  placeholder-polygon landmarks — a grey/gold **Standing Stone** (north, marks the
  Elder/Merchant/Finn village cluster) and a green **Lone Tree** (west, marks Mira's garden
  path). Purely visual (no collision/script), additive (no existing node moved). Branch
  `slice-map-landmarks`. Live-verified from spawn: both readable from a screen away, the two
  forks distinguishable at a glance.

- **Gentle repeatable coin faucet: a slow Meadow Slime respawn** → shipped a standalone
  `scripts/enemies/Spawner.gd` attached to the `Enemies` node in `Main.tscn`, which records
  each Meadow Slime's spawn position and re-instances one at the same position a slow, tunable
  `respawn_delay_sec` (default 25s) after it dies, capped at the original 3 so the zone never
  crowds. Cap/cadence decisions are pure static functions (`should_schedule_respawn`,
  `count_due`), covered by a new isolated `tests/spawner_tests.gd`.
  `docs/design/GEAR_AND_ECONOMY.md`'s faucet note is updated from "flagged" to "addressed".
  Branch `slice-coin-faucet`.

- **Combat hit-flash: brief pop on hit/hurt** → shipped as a reusable `HealthComponent`
  behavior (scale pop + white tint, pure tested easing in `tests/hit_flash_tests.gd`) plus a
  soft-red player-hurt variant in `Player.gd`. Branch `slice-hit-flash` / PR #43, merged.

_(Note: the "shop restock reason / coin sink" slice also shipped as the Legendary Dawnbringer
Blade on branch `slice-legendary-weapon` / PR #40 — its Done entry lives on that branch; these
two expansion PRs are disjoint in code and will both land here on merge.)_

_(further completed slices move here with a one-line note and the PR/commit that shipped them.)_

- **Add a shop restock reason: a second, tiny coin faucet** → shipped as the Legendary
  **Dawnbringer Blade** (+4 dmg, 30 coins) — a 4th weapon and aspirational top-of-shop coin
  sink, data-driven add reusing `GearDefinition`/`ShopUI`. Branch `slice-legendary-weapon`
  (PR opened by the expansion loop). Follow-up surfaced: the coin **faucet** (3
  non-respawning Meadow Slimes) is the real pacing bottleneck — recorded in
  `docs/design/GEAR_AND_ECONOMY.md` as the natural next economy slice.
