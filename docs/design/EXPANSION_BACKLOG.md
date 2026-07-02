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

<!-- Third expansion pass (game-architect refill, 2026-07-01). Planned assuming BOTH the epic
     region-distinct map pass (village green / flower meadow / forest edge / lake / rocky
     border) AND the Elder Slime mini-boss have merged — the two in-flight PRs are treated as
     ground truth here. Research provenance: docs/design/RESEARCH_NOTES.md §8 (kid-stickiness
     without dark patterns + stealth-learning). Ordered best-next-first, each with a Sequencing
     note on conflict-risk against the still-settling map/mini-boss code. The prior pass's
     "Creatures met" codex and Elder Slime slices have shipped/merged and moved to Done. -->

### Diegetic session-end "rest" beat: a cozy campfire that banks the session
- **Goal:** Add a single cozy in-fiction "rest" spot (a campfire or bedroll in the village)
  the child can walk up to and choose to rest at; resting shows a warm "You rest by the fire —
  your progress is safe. See you next time!" beat and a gentle fade, giving the session a
  *satisfying stopping point* instead of an open "one more thing" loop.
- **Design rationale:** NORTH_STAR pillar 5 (every session yields permanent progress — make
  that *visible* at the natural stopping point) AND the project's anti-dark-pattern safety
  posture | research: `RESEARCH_NOTES.md` §8.1 — the CHI 2026 disengagement-friendly study
  found an in-fiction bedtime/rest beat helps children *anticipate and accept* the end of a
  session and gives a parent a shared story to end play, the ethical inverse of a retention
  hook; §8.1 also warns any engagement reward must be additive-only with no penalty/FOMO.
- **Acceptance criteria:**
  - [ ] One interactable "rest" spot (campfire/bedroll) in the village hub; interacting opens
        a warm, short, profile-aware dialogue confirming progress is saved and inviting the
        child to stop for now.
  - [ ] Resting triggers an explicit `GameState.save_game()` and a gentle visual beat (a brief
        fade or a calm "resting" overlay) — NOT a game-over/quit; the child can keep playing if
        they choose. The point is a *clean, inviting stopping point*, never a forced exit.
  - [ ] No streak, no timer, no "come back tomorrow" FOMO, no reward that is *lost* by not
        resting — purely a positive, penalty-free closure beat (honors §8.1's dark-pattern
        warning and the bonus-only rule).
  - [ ] Reuses the existing `DialogueBox` + NPC-interaction pattern; no new persistent state
        schema needed beyond calling the existing save (so save schema stays put).
  - [ ] Grade 2 gets a shorter, plainer rest message; Grade 5 a slightly richer one — same
        two-profile scaffolding as every other piece of text.
- **Likely files touched:** `scenes/npcs/` or `scenes/props/` (a `Campfire`/`RestSpot` scene +
  script, mirroring an NPC's interact pattern), `scenes/main/Main.tscn` (one placement),
  `scripts/ui/DialogueBox.gd` (reuse), possibly a tiny fade overlay in a UI scene, `tests/`
  only if any pure logic is added (the save call itself is already tested).
- **Curriculum tie-in:** none — pure systems / player-wellbeing feature.
- **Sequencing:** **build after the region-map PR merges** (it places a node in `Main.tscn`).
  Otherwise self-contained; no dependency on the mini-boss or keepsake slices. Independently
  shippable and low-risk once the map settles.
- **Status:** ready

### Stealthier numeracy: make one existing coin-comparison check an in-fiction action
- **Goal:** Convert ONE existing numeracy learning check (Yarrow's Grade 2 "which coin is
  worth more?" / the analogous Grade 5 numeracy prompt) from an abstract multiple-choice quiz
  into a small *in-fiction action* — e.g. "hand Yarrow the right number of coins" or "choose
  the heavier pouch" — so the same already-confirmed skill is exercised through the fiction
  instead of a bolted-on quiz, while staying strictly bonus-only.
- **Design rationale:** NORTH_STAR pillar 3 ("quests are playable arcs, not quizzes in
  disguise") AND pillar 1 (deepen an *existing* quest, don't add a new one) | research:
  `RESEARCH_NOTES.md` §8.2 — the intrinsic-integration principle: "the work is the game";
  the named failure mode is the reward-for-work split (a quiz bolted onto play), and the fix
  is to express the skill as an in-fiction action with natural feedback. This is the honest,
  in-scope step toward the stealth-assessment bridge `CURRICULUM_MAP.md` already names.
- **Acceptance criteria:**
  - [ ] Exactly ONE existing check is reworked (not a new quest, not a new subject) — reuses
        the **already-confirmed** numeracy competency for that quest, so it does **not** trip
        the subject-scope CONFIRM gate (see §8.2's note: changing *format* is fine; changing
        *which subject* is not).
  - [ ] The check is expressed as an in-fiction choice/action (hand over coins / pick the
        heavier pouch / count out the right amount) rather than an abstract "which is bigger?"
        prompt, with the fiction reading naturally for the NPC involved.
  - [ ] Strictly bonus-only and non-punitive: the quest **always completes** regardless of the
        answer (unchanged from today); a correct in-fiction action still awards the same bonus
        badge; a wrong one still completes the quest with no penalty and no scolding — only a
        gentle, friendly in-fiction acknowledgement.
  - [ ] Grade 2 and Grade 5 framings both preserved (two-profile scaffolding), each mapping to
        that quest's existing confirmed competency.
  - [ ] Existing `LearningCheck` tests still pass; if new branching logic is added, it's
        covered at the same pure-logic level the current checks are.
- **Likely files touched:** `scripts/ui/LearningCheck.gd` (or a small sibling UI if the action
  format diverges enough), the affected NPC script (`scripts/npcs/Yarrow.gd` or similar),
  `scripts/core/ContentDefinitions.gd` (prompt/flavor text), `tests/game_state_tests.gd` or a
  focused new test file, `docs/design/CURRICULUM_MAP.md` (note the reworked check's format).
- **Curriculum tie-in:** **Directly deepens** an existing confirmed-subject check
  (`CURRICULUM_MAP.md`'s Yarrow row, G2 money/number-sense) — same subject, stealthier format.
  Does NOT introduce a new subject, so it is NOT CONFIRM-gated.
- **Sequencing:** Independent of the map/mini-boss PRs (touches quest/UI code, not `Main.tscn`
  geometry) — can be built any time. Ordered below the map-dependent slices only because the
  keepsake and discovery slices complete freshly-merged systems; this one is a refinement.
- **Status:** done

### Region ambience pass: per-region ambient sound as the player crosses the new map
- **Goal:** Give each distinct region of the new map its own quiet ambient sound bed (meadow
  birds in the flower meadow, gentle wind/rustle at the forest edge, soft water lap by the
  lake) that cross-fades as the player moves between regions — so the region-distinct *visual*
  map pass is matched by a region-distinct *audio* feel, deepening immersion.
- **Design rationale:** NORTH_STAR pillar 1 ("cohesion over volume" — make the just-shipped
  map pass *pay off* across senses rather than adding new content) | research:
  `RESEARCH_NOTES.md` §8.3/§8.4 — the calm, autonomy-and-immersion Zelda-like feel (the
  healthy inverse of compulsion) comes from a world that rewards *being there*; §7.1's
  gentle-feedback rule for a Grade 2/5 audience (soft, never overwhelming) also governs this.
- **Acceptance criteria:**
  - [ ] Each new region has its own quiet ambient loop; the current single global meadow
        ambient (`AudioManager`) is generalized so the *active* region's ambient plays and
        cross-fades gently when the player crosses a region boundary — no hard cut, no silence
        gap.
  - [ ] Region detection is simple and cheap (e.g. rectangular region zones the player's
        position is tested against, or an `Area2D` per region) — no navmesh, no new heavy
        system; reuse the existing `AudioManager` autoload rather than adding a parallel one.
  - [ ] All ambient tracks are self-synthesized or CC0-clean (matching the existing
        `assets/audio/gen_sfx.py` provenance precedent — no third-party-license risk) and
        deliberately **soft** (in the existing -18 dB ambient range) for the young audience.
  - [ ] Any pure logic (which region a position falls in, cross-fade easing) is extracted into
        testable static functions and covered, mirroring `AudioManager.coins_increased()`'s
        precedent (`tests/audio_tests.gd`).
  - [ ] No gameplay change: this is atmosphere only; nothing about combat, quests, or rewards
        is affected.
- **Likely files touched:** `scripts/core/AudioManager.gd`, region-zone data (either
  rectangles in code or `Area2D` nodes in `scenes/main/Main.tscn`), `assets/audio/`
  (new ambient loops + `gen_sfx.py`), `tests/audio_tests.gd` + possibly `test_runner.gd`.
- **Curriculum tie-in:** none — pure atmosphere/systems.
- **Sequencing:** **build after the region-map PR merges** — region boundaries are defined by
  that map's layout; building before it lands means guessing region geometry that will move.
  Lower priority than the keepsake/discovery/rest slices (atmosphere, not a progress loop), but
  a strong cohesion payoff once the map is stable.
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

### Discovery sparkle-spots: hidden finds across the new region map
- **Goal:** Scatter a few hidden "sparkle spots" across the new region-distinct map (a
  shimmer in the flower meadow, a hollow at the forest edge, a glint by the lake) that, when
  found and touched, give a small bonus (a coin or two) and record a permanent "Places
  discovered" entry — turning the new map's regions into a curiosity/exploration reward loop.
- **Status:** done: `GameState.places_discovered` (Dictionary, save-schema-compatible via
  `.get()` default) + idempotent `discover_place(id)` (`place_discovered` signal fires once) +
  `has_discovered_place(id)`, mirroring `creatures_met`/`record_creature_met` exactly. A new
  `scripts/items/SparkleSpot.gd` / `scenes/items/SparkleSpot.tscn` pickup (pale-gold star
  polygon shimmer) mirrors `Collectible.gd`/`CoinPickup.gd`'s pickup shape, awarding a small
  coin bonus (1-2) and recording the discovery on touch. Four spots placed in `Main.tscn`,
  each in a distinct region: `FlowerMeadowSparkle` (flower meadow), `ForestEdgeSparkle`
  (forest edge), `LakeShoreSparkle` (lake sand shore), `RockyBorderSparkle` (rocky border
  corner) — all clear of existing NPC/item/path/prop positions.
  `ContentDefinitions.PLACE_FACTS` (plain dictionary, 4 entries) backs a new "Places
  discovered" section in `CharacterPanel`. 4 new tests in `tests/discovery_tests.gd`.

### Boss keepsake: Elder Slime drops a permanent trophy, not just a stat
- **Goal:** Defeating the Elder Slime mini-boss grants a one-time **keepsake** — a named
  trophy shown in a "Keepsakes" line of the character panel (e.g. "Elder Slime's Dewdrop") —
  so the fight leaves behind a memorable, permanent mark of the achievement rather than only
  coins or a codex tick.
- **Status:** done — shipped on `slice-boss-keepsake`: `GameState.keepsakes` (Dictionary,
  save-schema-compatible via `.get()` default) + idempotent `award_keepsake(id)`
  (`keepsake_awarded` signal fires once) + `has_keepsake(id)`, mirroring
  `creatures_met`/`record_creature_met` exactly. `ElderSlime._on_died()` now calls
  `award_keepsake("elder_slime_dewdrop")` alongside its existing codex record.
  `ContentDefinitions.KEEPSAKE_FACTS` (plain dictionary, one entry) backs a new "Keepsakes"
  section in `CharacterPanel`. 4 new tests in `tests/keepsake_tests.gd`.

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

- **"Creatures met" codex: permanent world-knowledge from combat** → shipped:
  `GameState.creatures_met` (Dictionary, save-schema-compatible via `.get()` default) +
  `record_creature_met(id)` (idempotent, `creature_met` signal fires once) +
  `has_met_creature(id)`; `MeadowSlime._on_died()` records `meadow_slime`;
  `ContentDefinitions.CREATURE_FACTS` (plain dictionary) backs a new "Creatures met" section
  in `CharacterPanel`; 4 new tests in `tests/codex_tests.gd`. This is the machinery the new
  "Boss keepsake" and "Places discovered" Ready slices deliberately mirror.

- **First mini-boss: Elder Slime (tougher Meadow Slime variant)** → shipped/in-flight (treated
  as merged for this planning pass): a larger, tougher Meadow Slime variant reusing the M2
  component architecture, more HP, one new telegraphed wind-up move, same non-punitive death
  rule, placed at a mid-point of the zone — no bespoke boss-UI/health-bar. Its reward payoff is
  intentionally left thin so the new "Boss keepsake" Ready slice can complete it.

_(further completed slices move here with a one-line note and the PR/commit that shipped them.)_

- **Add a shop restock reason: a second, tiny coin faucet** → shipped as the Legendary
  **Dawnbringer Blade** (+4 dmg, 30 coins) — a 4th weapon and aspirational top-of-shop coin
  sink, data-driven add reusing `GearDefinition`/`ShopUI`. Branch `slice-legendary-weapon`
  (PR opened by the expansion loop). Follow-up surfaced: the coin **faucet** (3
  non-respawning Meadow Slimes) is the real pacing bottleneck — recorded in
  `docs/design/GEAR_AND_ECONOMY.md` as the natural next economy slice.
