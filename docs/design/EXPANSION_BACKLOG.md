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

## Planning baseline for this pass (2026-07-01, fifth pass — refill v5)

`main` is at **PR #68**, with refill v4's **7 slices all shipped and merged**: day-warmth
atmosphere, ambient region particles, living lake shimmer, Merchant coin-counting, Elder
comprehension questions, palette-lock (15 named colors in `STYLE_GUIDE.md`), and Mossy's real
2-frame sprite. The suite is **102/102 across 17 suites** (all reflected in
`docs/CURRENT_STATE.md`). Earlier baselines (M3 gear/shop, M4 pets, the Epic map pass) are all
merged; nothing here re-proposes their deferred scope (sell-back, multi-slot loadouts,
consumables, pet combat, gear stat axes beyond `damage_bonus`, or a whole new biome).

**Owner mandate this pass, unchanged & verbatim:** "Cool backgrounds, epic art, and learning
out the wazoo." This refill picks, per the fresh research in `docs/design/RESEARCH_NOTES.md`
§10, from four candidate fronts: **A) world-art depth** (region-signature props, path-side
flowers — make each region a postcard), **B) learning breadth within confirmed subjects**
(expand the tiny numeracy CombatQuestion pool with a gentle difficulty ramp; a literacy beat at
a signpost), **C) systems payoff** (a second pet species earned by a *different existing*
accomplishment; a second mini-boss variant), and **D) game-feel** (a gentle, kid-noticed
pickup pop — no screen-shake).

**Map-conflict staggering (read before sequencing):** several FRONT A slices each edit
`scenes/main/Main.tscn` (adding prop instances in different regions). They are independent in
*design* but will textually conflict if built in parallel, so each is flagged **"touches
Main.tscn — stagger"** and the conductor should land them one at a time, rebasing the next on
the prior. The FRONT B/C/D slices below that touch only scripts/scenes other than `Main.tscn`
can run alongside a Main.tscn slice.

**CONFIRM-gate reminders honored this pass:** the numeracy-pool expansion (Slice 2) stays
strictly inside the already-confirmed numeracy subject (format/breadth-deepening, same
reasoning as the shipped Yarrow reframe and Merchant coin-counting), so it does NOT trip the
gate. The **signpost literacy beat** (Slice 6) is authored bonus-only within the
already-confirmed *literacy* subject as a village-prop reading beat (not a new subject, not a
5th quest) — but because putting a *literacy* question type into the numeracy-only **combat**
system would be a scope change, that specific variant is explicitly kept OUT of Slice 2 and
flagged. A genuine 5th quest / new subject remains `blocked: needs-user-input` below.

---

## Ready

<!-- Fifth expansion pass (game-architect refill v5, 2026-07-01) — owner mandate "Cool
     backgrounds, epic art, and learning out the wazoo." Refill v4's 7 slices all shipped/merged
     (moved to Done). Research provenance: docs/design/RESEARCH_NOTES.md §10 (world-art depth via
     region-signature props, question-pool variety, kid-noticed gentle game-feel), building on
     §7-§9. Ordered best-next-first. Every art slice is producible in-repo (Godot polygons/
     particles/tweens or procedural Python) and placeholder-fallback-safe; every learning slice
     stays inside the ALREADY-CONFIRMED numeracy/literacy subjects (format/breadth-deepening only,
     so none trip the CONFIRM gate) and is strictly bonus-only. FRONT A slices that add prop
     instances to Main.tscn are flagged "touches Main.tscn — stagger": land them one at a time.
     The FRONT B/C/D slices touch code other than Main.tscn geometry and can run alongside a
     Main.tscn slice. -->

### 1. Forest-edge signature: pine-cluster props along the west forest band
- **Goal:** Give the west forest-edge region its own recognizable silhouette by scattering a
  small cluster of tall pine/conifer props (distinct from the existing rounded `LoneTree`) along
  the forest band near Mira, so the region reads as "forest" from a distance instead of just
  being darker-green tiles.
- **Design rationale:** NORTH_STAR pillar 1 ("cohesion over volume" — deepen the *existing*
  forest-edge region, not add a new biome) and the owner's "epic art / postcard" mandate |
  research: `RESEARCH_NOTES.md` §10.1 — a district becomes legible when a *recurring* signature
  prop (pine silhouettes at a forest edge) is held consistently across the region; a single tree
  doesn't read as forest, a repeated silhouette does.
- **Acceptance criteria:**
  - [ ] A new `scenes/props/PineTree.tscn` placeholder-polygon prop with a **distinct tall,
        narrow, triangular conifer silhouette** (clearly different from `LoneTree`'s rounded
        canopy), colors sampled from the locked shared palette (`forest_floor`/`grass_dark` for
        the body, per `STYLE_GUIDE.md`) — no collision, no script, `y_sort_enabled` like the other
        props.
  - [ ] 4–7 instances placed in the forest-edge band (the darker forest-floor tiles along the west
        edge near Mira/LoneTree), massed as a cluster (not evenly spaced) so they read as a
        treeline, clear of the walkable path and every existing NPC/item position.
  - [ ] Purely visual and gameplay-neutral: no collision, no quest/combat effect; additive (no
        existing node moved).
  - [ ] Verifiable via a headless `Main.tscn` node-presence/position assertion (the pines exist in
        the forest region's coordinate range) plus a live screenshot showing the forest edge now
        reads as a treeline.
- **Likely files touched:** `scenes/props/PineTree.tscn` (new), `scenes/main/Main.tscn` (instance
  the cluster), `tests/map_tests.gd` or a small new `tests/props_tests.gd` (+ `test_runner.gd`)
  for the node-presence assertion.
- **Curriculum tie-in:** none — pure atmosphere/art.
- **Sequencing:** **Touches Main.tscn — stagger.** Independent in design from the other prop
  slices but will conflict textually with them; land first (it is the strongest single "postcard"
  upgrade because the forest band is the largest under-propped region). Rebase the next Main.tscn
  slice on this one.
- **Status:** ready

### 2. Expand the combat numeracy pool with a gentle difficulty ramp
- **Goal:** Grow the tiny 3-item-per-profile `CombatQuestion` pool into a dozen-plus items per
  profile arranged easiest-to-hardest, and stop it re-serving the same question back-to-back — so
  a child who fights for more than a minute meets varied numeracy practice instead of the same
  three questions on a loop.
- **Design rationale:** NORTH_STAR pillar 3 ("quests are playable arcs, not quizzes in disguise" —
  variety keeps the bonus lane fresh) and the owner's "learning out the wazoo" mandate | research:
  `RESEARCH_NOTES.md` §10.2 — a tiny item pool causes "early repetition," the named failure mode;
  a wider pool "in different difficulties" is both more motivating and better for understanding,
  and a cheap no-immediate-repeat draw gets most of the spaced-repetition benefit without an SRS.
- **Acceptance criteria:**
  - [x] Stays strictly inside the **already-confirmed numeracy** subject (`CombatQuestion.gd` is
        numeracy-only by explicit design) — a breadth/format change, NOT a new subject or quest,
        so it does **not** trip the CONFIRM gate. **Do NOT add a literacy question type to combat**
        (that would be a scope change — see Slice 6 and the CONFIRM reminder in the planning
        baseline).
  - [x] Each profile's pool grows to **at least 12 items**, ordered as a gentle ramp — Grade 2:
        +1/+2 sums → small teen sums → simple more/less compares; Grade 5: single-digit × →
        two-digit × → halves → quarters/thirds — all two-choice, one plausible distractor, matching
        the existing item shape. Text stays short/plain for G2 per `STYLE_GUIDE.md`.
  - [x] The draw **avoids re-serving the item just shown** (track the last index; pick from the
        rest) so back-to-back repeats don't happen — implemented as a small **pure, testable**
        function (e.g. `CombatQuestion.pick_next_index(pool_size, last_index, roll)`), mirroring
        `MeadowSlime.rolls_bonus_coin()`'s deterministic-test precedent; a single-item pool must
        not divide-by-zero or loop forever (edge case covered).
  - [x] Bonus-only unchanged: a correct answer still bumps the streak, a wrong/skipped answer never
        penalizes — pure content/variety expansion, no rule change.
  - [x] A new isolated `tests/combat_question_tests.gd` (registered in `test_runner.gd`) covers the
        no-repeat draw (never returns `last_index` for pool size > 1; valid index for size 1) and
        asserts each profile pool has the target minimum item count.
- **Likely files touched:** `scripts/ui/CombatQuestion.gd` (expand `QUESTION_POOL`, add the pure
  draw function, use it in `show_question()`), a new `tests/combat_question_tests.gd` +
  `tests/test_runner.gd`. Optionally a one-line note in `docs/design/CURRICULUM_MAP.md` that the
  combat numeracy pool was broadened (same not-CONFIRM-gated reasoning as the Yarrow/Merchant rows).
- **Curriculum tie-in:** **Directly deepens** the confirmed numeracy subject in the combat loop —
  same subject, more items, gentle ramp. NOT CONFIRM-gated.
- **Sequencing:** Independent of every Main.tscn slice (touches only `CombatQuestion.gd` + a new
  test) — can run in parallel with any FRONT A prop slice. Highest-value learning slice this pass:
  it fixes a live, owner-visible weakness (the same 3 questions repeat) with a tiny pure change.
- **Status:** done

### 3. Gentle pickup pop: a squash-and-stretch tween on coins and collectibles
- **Goal:** When the player grabs a coin or a collectible/sparkle-spot, give it a brief
  scale-up-and-settle "pop" (and optionally a tiny sparkle) so the reward reads as satisfying and
  intentional instead of the item just vanishing — the single most kid-noticed game-feel upgrade,
  kept gentle.
- **Design rationale:** NORTH_STAR pillar 3 (a *visible consequence* the child feels) and pillar 5
  (make the existing permanent-progress pickups pay off) | research: `RESEARCH_NOTES.md` §10.3 —
  squash-and-stretch / a scale pop plus a small sparkle on a pickup is the highest-signal,
  lowest-cost "juice" children feel; the CHI 2024 study ties it to healthy curiosity/competence
  motivation. The §7.1 over-juice caution binds: no screen-shake, keep it small.
- **Acceptance criteria:**
  - [ ] On pickup, the collected sprite plays a brief **scale pop** (a quick grow-then-settle, ~0.2s,
        small amplitude) via a `Tween` before it frees itself — reusing the same tween approach
        `Campfire`'s flame flicker and `HealthComponent`'s hit-flash already use (no new dependency).
  - [ ] Optionally a **sparse, brief sparkle burst** (native `CPUParticles2D`, one-shot, a handful
        of particles, colors from the locked palette's flower accents) at the pickup point — sparse
        and gentle per the kid-audience rule; skip it if it complicates the free timing.
  - [ ] **No screen-shake** (banned) and no gameplay change: the pickup still awards exactly what it
        did before (coin count / collected item / codex entry), just with feedback; the pop must not
        delay or drop the award (award first, or ensure the tween can't be interrupted before the
        award fires).
  - [ ] Applies to `CoinPickup` at minimum; ideally the shared `Collectible` too (and thus the
        merged `SparkleSpot`) so all pickups feel consistent — but scope to `CoinPickup` +
        `Collectible` only, not a generic effects framework.
  - [ ] Any easing/timing math extracted is a pure, tested function (mirroring
        `HealthComponent.hit_reaction_intensity()`); a headless test asserts the pop doesn't change
        the awarded amount. Live screenshot/playtest confirms the feel.
- **Likely files touched:** `scripts/items/CoinPickup.gd`, `scripts/items/Collectible.gd` (add the
  pop tween on collect), possibly a tiny shared `scripts/fx/` helper if the tween is duplicated,
  possibly a one-shot particle scene under `scenes/fx/`, a new `tests/pickup_pop_tests.gd` +
  `tests/test_runner.gd`. **Does not touch Main.tscn geometry.**
- **Curriculum tie-in:** none — pure game-feel.
- **Sequencing:** Independent of every Main.tscn slice (touches pickup scripts) — can run in
  parallel with a FRONT A prop slice. A strong, cheap, immediately-felt win.
- **Status:** ready

### 4. Lake-shore signature: reed clusters along the lake edge
- **Goal:** Give the lake shore its own recognizable silhouette with a small cluster of tall reed
  props at the water's edge near the Dock, so the lake region reads as a living wetland edge
  rather than a plain sand ring — and the Dock gets some company.
- **Design rationale:** NORTH_STAR pillar 1 (deepen the *existing* lake region, not add water
  elsewhere) and the owner's "postcard" mandate | research: `RESEARCH_NOTES.md` §10.1 — reeds/tall
  grasses clustering at a water's edge are the canonical low-cost signature prop that makes a
  wetland read at a glance; a recurring silhouette, held along the shore, is what gives the region
  its character.
- **Acceptance criteria:**
  - [ ] A new `scenes/props/Reeds.tscn` placeholder-polygon prop — a small cluster of thin vertical
        blades with a distinct wetland silhouette, colors from the locked shared palette
        (`grass_dark`/`forest_floor` greens, maybe a `sand` base), no collision, no script,
        `y_sort_enabled`.
  - [ ] 3–6 instances placed along the lake's sand shore near the Dock (on walkable sand tiles, not
        in the impassible water), massed as clusters, clear of the walkable dock approach and every
        existing position.
  - [ ] Purely visual and gameplay-neutral: no collision, no quest/combat effect; additive.
  - [ ] Verifiable via a headless `Main.tscn` node-presence/position assertion (reeds sit in the
        lake-shore coordinate range) plus a live screenshot showing the shore now reads as a reedy
        edge.
- **Likely files touched:** `scenes/props/Reeds.tscn` (new), `scenes/main/Main.tscn` (instance the
  cluster), `tests/map_tests.gd` or `tests/props_tests.gd` (+ `test_runner.gd`).
- **Curriculum tie-in:** none — pure atmosphere/art.
- **Sequencing:** **Touches Main.tscn — stagger.** Land after Slice 1 (rebase on it). Independent
  in design; grouped with the other prop slices for the conductor to sequence one-at-a-time.
- **Status:** ready

### 5. Rocky-border signature: boulder scatter along the map's rock edge
- **Goal:** Give the rocky-border region its own recognizable silhouette with a scatter of small
  boulder props along the map's rock/cliff frame, so the border reads as a rugged rocky edge
  rather than just the impassible cliff tiles — completing the "every region has a signature prop"
  set.
- **Design rationale:** NORTH_STAR pillar 1 (deepen the *existing* rocky border region) and the
  owner's "postcard" mandate | research: `RESEARCH_NOTES.md` §10.1 — boulders/rock scatter marking
  a rocky/mountain border is the canonical signature prop; a recurring silhouette gives the region
  its character and reinforces the soft diegetic blockade the cliff already provides.
- **Acceptance criteria:**
  - [ ] A new `scenes/props/Boulder.tscn` placeholder-polygon prop (a rounded grey rock, distinct
        from the taller `StandingStone`), colors from the locked shared palette (`rock`/`cliff`),
        no collision (the cliff tiles behind it already gate movement), no script, `y_sort_enabled`.
  - [ ] 5–8 instances scattered along the interior of the rock/cliff border in a couple of the
        map's corners/edges, clustered naturally, clear of walkable paths and every existing
        position.
  - [ ] Purely visual and gameplay-neutral: no collision, no quest/combat effect; additive.
  - [ ] Verifiable via a headless `Main.tscn` node-presence/position assertion (boulders sit near
        the border coordinate range) plus a live screenshot showing the border reads as rocky.
- **Likely files touched:** `scenes/props/Boulder.tscn` (new), `scenes/main/Main.tscn` (instance
  the scatter), `tests/map_tests.gd` or `tests/props_tests.gd` (+ `test_runner.gd`).
- **Curriculum tie-in:** none — pure atmosphere/art.
- **Sequencing:** **Touches Main.tscn — stagger.** Land after Slices 1 and 4 (rebase on the latest).
  Independent in design; the last of the three region-signature prop slices.
- **Status:** ready

### 6. Village signpost: a bonus-only literacy word-building beat at a new prop
- **Goal:** Add a small readable signpost prop in the village that, when read, offers ONE optional,
  friendly bonus-only literacy beat drawn from the already-confirmed literacy subject (Grade 2:
  which word starts with the same sound / rhymes; Grade 5: which word fits / means the same) — so
  the village gains a stealth literacy touchpoint without a new quest or NPC.
- **Design rationale:** NORTH_STAR pillar 3 (fiction carries the skill — a signpost is a natural
  reading object) and pillar 1 (deepen the *existing* village hub, not add an NPC) | research:
  `RESEARCH_NOTES.md` §10.1 (signposts/props as district touchpoints) and §9.2/§8.2 (intrinsic
  integration — the reading object *is* the practice); the "signpost word-building" idea floated in
  §9. Uses the already-confirmed literacy competency.
- **Acceptance criteria:**
  - [ ] Reuses the **already-confirmed** literacy competency (phonics/rhyme for G2; word choice/
        meaning for G5) — a new stealthy touchpoint on an existing subject, NOT a new subject and
        NOT a 5th quest (no fetch item, no gate chain, no new NPC archetype), so it does **not**
        trip the CONFIRM gate. If an implementer reads this as a new subject or quest, that is a
        bug in the slice — stop and re-file, do not proceed.
  - [ ] A new `scenes/props/Signpost.tscn` placeholder-polygon prop with an `InteractionArea` +
        "Press E" prompt (mirroring `Campfire.gd`'s interact pattern exactly — no quest state),
        placed once in the village green clear of every existing NPC/prop/path.
  - [ ] Interacting offers ONE short, friendly, profile-aware two-choice literacy question via the
        existing `LearningCheck` shape (or `CombatQuestion`'s lighter shape). **Strictly bonus-only
        and skippable:** a correct answer awards a bonus (matching the `award_quest_bonus`/badge
        pattern); wrong or skipped never blocks or penalizes; the child can walk away and lose
        nothing. Reading the sign always "works."
  - [ ] G2 and G5 framings both present against the same confirmed literacy competency; G2 text
        short/plain per `STYLE_GUIDE.md`.
  - [ ] Answer-checking is a pure, tested function (reuse the existing check's logic, don't invent a
        bespoke UI); a new isolated test file covers it. Placeholder-polygon art, in-repo.
- **Likely files touched:** `scenes/props/Signpost.tscn` + `scripts/props/Signpost.gd` (new,
  mirroring `Campfire`), `scenes/main/Main.tscn` (instance once), `scripts/core/ContentDefinitions.gd`
  (prompt/answer text), reuse `scripts/ui/LearningCheck.gd`, a new `tests/signpost_tests.gd` +
  `tests/test_runner.gd`, `docs/design/CURRICULUM_MAP.md` (note the literacy signpost touchpoint,
  same not-CONFIRM-gated reasoning as the Yarrow/Merchant rows).
- **Curriculum tie-in:** **Directly deepens** the confirmed literacy subject via a new village
  reading touchpoint — same subject, new stealthy format. NOT CONFIRM-gated (it is not a quest).
- **Sequencing:** **Touches Main.tscn — stagger** (adds one prop instance). Land after the three
  region-signature prop slices, or interleave since it is a single instance. Its script/content/
  test work is independent; only the one `Main.tscn` instance line must be staggered.
- **Status:** ready

### 7. Second pet: earn a companion from the Elder Slime keepsake
- **Goal:** Add a second pet species unlocked by a *different existing* accomplishment — defeating
  the Elder Slime mini-boss (which already grants the Dewdrop keepsake) — so the pet roster the M4
  structure already supports finally has a second member, earned through combat rather than the
  same all-four-quests gate as Mossy. No pet combat.
- **Design rationale:** NORTH_STAR pillar 5 (a memorable, permanent payoff for the mini-boss beyond
  the keepsake) and pillar 1 (make the *existing* pet + mini-boss + keepsake systems pay off
  together, not a parallel system) | research: `RESEARCH_NOTES.md` §7.3/§8.4 (collection/keepsake
  payoff psychology) and §10.1's cohesion framing; `docs/design/PETS.md` explicitly says "Adding
  future pets is additive" and documents the exact recipe.
- **Acceptance criteria:**
  - [ ] A second `PetDefinition` `.tres` under `data/pets/` (id/label/rarity/hp_bonus), registered
        in `ContentDefinitions`' pet lookup exactly as `docs/design/PETS.md`'s "Adding future pets"
        recipe prescribes — additive, no change to the shared unlock/equip/follow contract.
  - [ ] Unlocked by **defeating the Elder Slime**, reusing the existing keepsake/boss-death hook
        (e.g. granted alongside `award_keepsake("elder_slime_dewdrop")` in `ElderSlime._on_died()`,
        or gated on `has_keepsake(...)`) — a *different* existing accomplishment from Mossy's
        all-four-quests gate, so the two pets don't share one trigger. Idempotent (grant fires
        once; owning it short-circuits), matching `_check_and_grant_first_pet()`'s precedent.
  - [ ] **No pet combat** (hard, per `docs/design/PETS.md`): the new pet is follow-only, no
        `HealthComponent`/hitbox/hurtbox — reuses `Pet.gd`'s follow AI. It can reuse `Pet.tscn` or
        get a small distinct placeholder-polygon/generated variant, but behavior is unchanged.
  - [ ] Equip/unequip semantics unchanged: single slot, ownership-gated equip, clamps hp down but
        never auto-heals on manual equip (only the grant path heals) — the existing `equip_pet`
        contract, extended to a second owned pet in the character panel's Pets list.
  - [ ] **Rarity color consistency** honored: the new pet's rarity tag uses the same
        `ContentDefinitions.RARITY_COLORS` mapping the shop/panel already use (a Common/Uncommon/
        Rare/Legendary bucket), so its label tints consistently with gear and Mossy.
  - [ ] Save/load-safe (the `owned_pets` array already round-trips; no schema bump needed — new pet
        id loads via the existing array coercion) and reset-safe. A new isolated
        `tests/second_pet_tests.gd` (+ `test_runner.gd`) covers the boss-death grant firing once,
        ownership/equip, and the save/load round trip; `docs/design/PETS.md` updated with the new
        pet row and its distinct unlock trigger.
- **Likely files touched:** `data/pets/<new_pet>.tres` (new), `scripts/core/ContentDefinitions.gd`
  (register it), `scripts/enemies/ElderSlime.gd` (grant hook on death), `scripts/core/GameState.gd`
  (a small `_check_and_grant_<pet>()` or reuse of the keepsake hook), possibly `scenes/pets/`
  (a variant scene if distinct art), `scripts/ui/CharacterPanel.gd` (already lists all owned pets —
  verify it handles two), a new `tests/second_pet_tests.gd` + `test_runner.gd`,
  `docs/design/PETS.md`. **Does not touch Main.tscn geometry.**
- **Curriculum tie-in:** none — pure systems/collection payoff.
- **Sequencing:** Independent of every Main.tscn slice (touches pet/enemy/state code) — can run in
  parallel with a FRONT A prop slice. A satisfying systems-payoff slice; lower priority than the
  visible art/game-feel/learning wins above but a clean deepening of three merged systems at once.
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

<!-- Refill v5 (2026-07-01): refill v4's 7 slices all shipped/merged (main at PR #68); moved to
     one-line entries below. Full writeups live in docs/CURRENT_STATE.md. -->

- **Ambient particle pass: drifting pollen + gentle fireflies per region** → shipped
  (`scripts/fx/AmbientParticles.gd` / `scenes/fx/AmbientParticles.tscn`, three fixed
  `CPUParticles2D` emitters in `Main.tscn` reusing `AudioManager.region_for_position()`;
  `tests/particle_tests.gd`, 9 tests). `RESEARCH_NOTES.md` §9.1.
- **Living lake: animated water shimmer** → shipped (`shaders/water_shimmer.gdshader` on a
  `ColorRect` in `scenes/fx/LakeShimmer.tscn`, instanced `World/LakeShimmer`; `tests/lake_tests.gd`,
  5 tests). `RESEARCH_NOTES.md` §9.1.
- **Count-out-the-coins at the Merchant: bonus-only numeracy on purchase** → shipped (optional
  coin-counting beat in the shop buy flow, bonus-only, G2 sum-to-price / G5 fewest-coins, pure
  tested logic). Confirmed-numeracy format-deepening, not CONFIRM-gated; `CURRICULUM_MAP.md`
  updated. `RESEARCH_NOTES.md` §9.2.
- **Elder's "what did you notice?": bonus-only reading comprehension** → shipped (Elder offers one
  optional comprehension question drawn from earned codex/keepsake flavor, bonus-only, data-driven
  per-entry). Confirmed-literacy format-deepening, not CONFIRM-gated. `RESEARCH_NOTES.md` §9.2.
- **Palette-lock pass: gen_tileset.py colors → one documented shared palette** → shipped (single
  named `PALETTE` dict in `gen_tileset.py`, byte-identical PNG, 15-color hex/role table in
  `STYLE_GUIDE.md`). `RESEARCH_NOTES.md` §9.1.
- **Character-sprite polish pass: Mossy → generated sprite** → shipped
  (`assets/sprites/pets/gen_mossy.py`, 2-frame idle-bob `AnimatedSprite2D` in `Pet.tscn`, strong
  outline for grass contrast; `tests/pet_sprite_tests.gd`, 2 tests). `RESEARCH_NOTES.md` §9.1.

- **Day-warmth atmosphere pass: a warm CanvasModulate wash + subtle vignette** → shipped:
  `World/DayWarmth` is a `CanvasModulate` (`Color(1.0, 0.965, 0.902, 1.0)`, a very slightly
  golden-white — chosen deliberately subtle given the repo's history of tint-related visibility
  bugs, e.g. Mossy green-on-green and Elder Slime camouflage) added under `World` in
  `scenes/main/Main.tscn`, so it tints the world only, never the UI (`CanvasLayer`s ignore
  `CanvasModulate` by construction — confirmed by a headless test). The vignette is a new
  `VignetteOverlay` `CanvasLayer` (`scenes/ui/VignetteOverlay.tscn`/`scripts/ui/
  VignetteOverlay.gd`, `layer = 0`, below every interactive UI `CanvasLayer`, all of which sit at
  `layer >= 1`) with a full-screen `TextureRect` showing a radial `GradientTexture2D`
  (`assets/ui/vignette_gradient.tres`, transparent center fading to `Color(0,0,0,0.35)` at the
  edge from 55% radius outward), `mouse_filter = MOUSE_FILTER_IGNORE` so it never blocks input.
  No shader used — a plain resource-backed texture satisfies the placeholder-fallback-safe
  criterion trivially (nothing to fail to compile). `RESEARCH_NOTES.md` §9.1;
  `docs/art/STYLE_GUIDE.md`'s art-direction one-pager. A new isolated `tests/atmosphere_tests.gd`
  (3 tests) is registered in `tests/test_runner.gd`: the `CanvasModulate` exists with bright/
  warm-leaning bounds, the vignette overlay exists and ignores mouse input, and its layer sits
  below every named interactive UI `CanvasLayer`. Suite total is now 71.

- **Stealthier numeracy: Yarrow's coin check as an in-fiction action** → shipped. Yarrow's
  Grade 2 prompt reframed from an abstract "Which coin is worth more?" to the in-fiction "The
  remedy jar costs a dime. Which coin do you hand me?" — same two coins, same correct answer,
  same already-confirmed G2 money/number-sense competency, same `LearningCheck`/bonus-only path
  (`RESEARCH_NOTES.md` §8.2). No new subject/mechanic/test surface. `CURRICULUM_MAP.md` updated;
  not CONFIRM-gated. See `docs/CURRENT_STATE.md`.

- **Discovery sparkle-spots: hidden finds across the region map** → shipped/in-flight (treated as
  merged): 3–5 `SparkleSpot` pickups reusing `Collectible`, a permanent "Places discovered"
  `GameState` codex (mirroring `creatures_met`, save/load-safe) surfaced in a new character-panel
  section, bonus-only, placeholder polygon art, isolated tests. `RESEARCH_NOTES.md` §8.3/§8.4.

- **Diegetic session-end "rest" beat: a cozy campfire** → shipped:
  one interactable village rest spot that opens a warm profile-aware dialogue, calls
  `GameState.save_game()`, and shows a gentle fade — a clean, penalty-free stopping point (no
  streak/timer/FOMO), reusing `DialogueBox`. `RESEARCH_NOTES.md` §8.1 (CHI 2026 disengagement-
  friendly design).

- **Region ambience pass: per-region ambient audio** → shipped:
  `AudioManager` generalized so each region's soft ambient loop cross-fades as the player crosses
  region boundaries (simple region-zone detection, self-synthesized/CC0 loops, -18 dB, pure-
  tested region/cross-fade logic). This pass's ambient-particle slice deliberately reuses this
  slice's region-detection helper. `RESEARCH_NOTES.md` §8.3/§8.4/§7.1.

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
