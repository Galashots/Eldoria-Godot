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

### Combat hit-flash: a brief white flash when something takes damage
- **Goal:** When the player hits an enemy (and when the player is hit), the struck sprite
  briefly flashes white, so a landed hit reads instantly — the single cheapest bit of "game
  feel" for the existing M2 combat.
- **Design rationale:** NORTH_STAR pillar "Cohesion over volume" — deepens the existing
  combat's readability, adds no new system | research: `RESEARCH_NOTES.md` §7.1 — a ~50-100ms
  white flash on hit is the highest-impact/lowest-cost juice ("Juice it or lose it" lineage);
  the "juice problem" counterpoint says keep it subtle, which suits a Grade 2/5 audience (a
  gentle flash, no screen shake).
- **Acceptance criteria:**
  - [ ] Taking damage briefly tints the struck entity's sprite toward white then restores it
        (~0.08s, tunable), implemented as a small reusable behavior on `HealthComponent`
        (flash an assigned sprite target) so any entity with a `HealthComponent` gets it.
  - [ ] The Meadow Slime flashes when the player hits it; the player flashes when hit (player
        has no `HealthComponent`, so its flash lives in `Player.gd`, mirroring the same timing).
  - [ ] No screen shake, no hit-stop in this slice (deferred per the "juice problem" caution);
        purely a color flash. No gameplay/damage/timing change to combat itself.
  - [ ] The flash's pure timing logic (e.g. a function mapping elapsed→tint) is unit-tested in
        an **isolated new test file** registered in `tests/test_runner.gd`, NOT appended to
        `game_state_tests.gd` (which is a merge hotspot right now).
- **Likely files touched:** `scripts/core/combat/HealthComponent.gd`,
  `scenes/enemies/MeadowSlime.tscn` (wire the Body as flash target — the `.tscn`, not the
  `.gd`), `scripts/player/Player.gd`, `scenes/player/Player.tscn`, new `tests/hit_flash_tests.gd`
  + `tests/test_runner.gd` (register it).
- **Curriculum tie-in:** none — pure systems.
- **Sequencing:** **conflict-free now** — touches none of the files in the open PR stack
  (#39 edits `MeadowSlime.gd` not `.tscn`; #40 edits gear/`ContentDefinitions`; #41 edits
  `Main.tscn`). `GameState.gd`/`HealthComponent.gd`/`Player.gd`/`test_runner.gd` are all free.
- **Status:** ready

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
- **Status:** ready

### Gentle repeatable coin faucet: a slow Meadow Slime respawn
- **Goal:** Make the coin faucet repeatable within a session so the shop roster (incl. the new
  30-coin Dawnbringer) stays reachable without grind — slain Meadow Slimes slowly respawn (up
  to the original count) at a gentle cadence.
- **Design rationale:** NORTH_STAR pillar "Every short session yields permanent progress" |
  research: `RESEARCH_NOTES.md` §7.2 (time-based respawn keeps a zone alive and lets a player
  choose to earn more) and the faucet-depth finding already recorded in
  `GEAR_AND_ECONOMY.md` — the flagged bottleneck is exactly this: 3 non-respawning slimes =
  ~3 coins/session. Keep the cadence slow and the cap at the original 3 so the zone never feels
  crowded or dangerous for a young audience.
- **Acceptance criteria:**
  - [ ] Defeated Meadow Slimes respawn after a slow, tunable delay, capped so the live count
        never exceeds the original 3 (no crowding).
  - [ ] Implemented as a small standalone `Spawner` node (disjoint from `MeadowSlime.gd`) that
        watches its spawn points and re-instances — not a rewrite of the slime.
  - [ ] Non-punitive: respawn is slow enough that clearing the area still gives a calm window;
        no new damage/difficulty.
  - [ ] `GEAR_AND_ECONOMY.md`'s faucet note is updated from "flagged" to "addressed".
  - [ ] Covered by an isolated new test file (spawn-count cap / cadence pure logic), registered
        in `test_runner.gd`.
- **Likely files touched:** new `scripts/enemies/Spawner.gd` (+ maybe a scene),
  `scenes/main/Main.tscn` (one Spawner node over the existing slime positions),
  `docs/design/GEAR_AND_ECONOMY.md`, new `tests/spawner_tests.gd` + `tests/test_runner.gd`.
- **Curriculum tie-in:** none — pure systems.
- **Sequencing:** **wait for PR #41 to merge** — adds a node to `Main.tscn`, which #41 also
  edits; build after #41 lands. Also coordinate with the Elder Slime slice (both touch the
  `Enemies` area of `Main.tscn`).
- **Status:** ready

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
  - [ ] Meadow Slime still always drops its existing guaranteed 1 coin (no regression).
  - [ ] A small, tunable chance (e.g. ~10-15%, tuned in-engine per the research caveat, not
        hardcoded blindly) adds one *additional* coin on top of the guaranteed drop — never
        removes or reduces the guaranteed drop.
  - [ ] The bonus-coin roll is implemented as a single exported probability on
        `MeadowSlime.gd` (or a tiny shared helper if a second enemy will reuse it soon), not
        a new generic loot-table framework — keep it proportional to one monster.
  - [ ] Test suite covers the roll deterministically (e.g. by seeding/mocking randomness or
        asserting the guaranteed-coin path is unaffected when the bonus roll fails/succeeds).
  - [ ] No visual/UI change required beyond the existing coin-drop pickup already shipped in
        M3; a second `CoinPickup` instance is an acceptable minimal presentation.
- **Likely files touched:** `scripts/enemies/MeadowSlime.gd`, `tests/game_state_tests.gd` (or
  a new enemy test file if one exists after M2/M3 land), `docs/design/GEAR_AND_ECONOMY.md`
  (append the bonus-drop rule to keep it authoritative).
- **Curriculum tie-in:** none — pure systems.
- **Status:** ready

### Add a shop restock reason: a second, tiny coin faucet
- **Goal:** Once a player owns all 3 M3 weapons, coins currently have nowhere to go. Add one
  small additional sink or faucet-pacing tweak so post-purchase coins still feel purposeful
  during a normal session, without inventing a new economy system.
- **Design rationale:** NORTH_STAR pillar "Every short session yields permanent progress" |
  research: "Value chains" (Lost Garden) and "The Principles of Building A Game Economy"
  (Department of Play), `docs/design/RESEARCH_NOTES.md` §6.2 — fixed-length/session games
  should size faucets against a tallied list of sinks, and a "pinch point" economy (scarce
  but not grindy) keeps pacing appropriate for a Grade 2/5 audience; avoid overshooting into
  a punishing/grindy economy per that same research.
- **Acceptance criteria:**
  - [ ] Exactly one small addition — either (a) a 4th, slightly pricier weapon reusing the
        exact same `GearDefinition` pattern (Rare or a new tier, priced so it's reachable
        within a normal session per the research's pacing guidance), or (b) a cheap
        repeatable sink (e.g. a "tip the Merchant" flavor interaction with no mechanical
        effect beyond a dialogue acknowledgment) — pick (a) unless a design review finds (b)
        clearly better; do not ship both in one slice.
  - [ ] If a 4th weapon: it's added to `data/gear/`, appears in `ShopUI`, and is purchasable
        and equippable exactly like the existing 3.
  - [ ] Price is tuned so a player who already owns the 3 existing weapons can reach it
        within roughly one more normal play session of Meadow-Slime coin farming (avoiding a
        grindy economy per the cited research) — document the assumed coins/session estimate
        in the PR description for future tuning.
  - [ ] `docs/design/GEAR_AND_ECONOMY.md`'s roster table is updated to include the addition.
  - [ ] Test suite covers purchase/equip of the new item exactly as it covers the existing 3.
- **Likely files touched:** `data/gear/` (new `.tres`), `scripts/ui/ShopUI.gd` (if the roster
  isn't already fully data-driven), `docs/design/GEAR_AND_ECONOMY.md`,
  `tests/game_state_tests.gd`.
- **Curriculum tie-in:** none — pure systems.
- **Status:** ready

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

### Map readability pass: landmark props near existing path forks
- **Goal:** Add 1-2 tall/distinctive landmark props (e.g. a large standing stone or a
  distinctive lone tree) near the existing path forks in the M1 zone, so a player can see at
  a glance which direction leads where, without adding a new biome or expanding the map.
- **Design rationale:** NORTH_STAR pillar "Cohesion over volume" (a readability pass on the
  existing single zone, not a new biome) | research: "Best Practices for Game Map Layout"
  (Sandboxr) and "Wayfinding" (The Level Design Book), `docs/design/RESEARCH_NOTES.md` §6.4 —
  readable layouts use landmarks and soft diegetic gating (already true of M1's lake/rock
  outcrops) but currently lack any long-range visual landmark pulling the player toward NPCs
  from a distance; a good readability test is whether a player can navigate by world cues
  alone.
- **Acceptance criteria:**
  - [ ] 1-2 new static, placeholder-art props (matching the existing bootstrap-placeholder
        convention — e.g. a simple colored polygon/sprite, not new production art) are placed
        at existing path forks in `scenes/main/Main.tscn`, tall/bright enough to be visible
        from a screen or more away.
  - [ ] Props are purely visual (no collision required, unless matching an existing obstacle
        pattern is trivially easy) — this is a readability slice, not a new gameplay
        mechanic.
  - [ ] No existing NPC/collectible/path position changes — this is additive only, preserving
        the already-tested playable slice.
  - [ ] Manual test checklist addition in `docs/CURRENT_STATE.md`: a player entering the zone
        for the first time can identify, from the landmark alone, which fork leads toward the
        already-visited vs. not-yet-visited NPCs.
- **Likely files touched:** `scenes/main/Main.tscn`, possibly one or two new placeholder
  sprite assets under `assets/sprites/`, `docs/CURRENT_STATE.md` (manual checklist).
- **Curriculum tie-in:** none — pure systems.
- **Status:** ready

---

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

_(empty — completed slices move here with a one-line note and the PR/commit that shipped them.)_
