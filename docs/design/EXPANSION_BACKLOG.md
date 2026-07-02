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

## Planning baseline for this pass (2026-07-01, fourth pass — owner "epic art + learning" mandate)

`main` is at commit `ad0ed3b` with **12 PRs merged this cycle** (pets, sound pass, creatures
codex, Elder Slime mini-boss + keepsake, epic region map 220x140 with village green / flower
meadow / forest edge / lake+dock / rocky border, slime respawn faucet, numeracy reframe) — all
reflected in `docs/CURRENT_STATE.md`. Earlier baselines (M3 gear/shop, M4 pets) are long since
merged; nothing here re-proposes their deferred scope (sell-back, multi-slot loadouts,
consumables, a second pet species, pet combat, gear stat axes beyond `damage_bonus`).

**Owner mandate this pass, verbatim:** "Cool backgrounds, epic art, and learning out the
wazoo." This refill mixes **art/atmosphere** slices (FRONT A) and **learning-deepening** slices
(FRONT B), all sourced to `docs/design/RESEARCH_NOTES.md` §9.

**Three in-flight slices are treated as merged ground truth and must NOT be re-proposed:**

- **Discovery sparkle-spots** — hidden finds across the region map (a `SparkleSpot` reusing
  `Collectible`, a "Places discovered" codex section, save-safe), being built now.
- **Campfire rest beat** — a diegetic session-end "rest" spot in the village that banks the
  session (reuses `DialogueBox` + `save_game()`), being built now.
- **Region ambience** — per-region ambient audio that cross-fades as the player crosses the map
  (generalizes `AudioManager`, adds simple region-zone detection), being built now.

Two of this pass's slices deliberately **build on the region ambience slice's region-zone
detection** (art particles per region) — sequencing notes below say so explicitly so the
orchestrator lands ambience first and the two share one region-detection helper (cohesion, not
a parallel system).

---

## Ready

<!-- Fourth expansion pass (game-architect refill, 2026-07-01) — owner mandate "Cool
     backgrounds, epic art, and learning out the wazoo." Mix of FRONT A (art/atmosphere) and
     FRONT B (learning-deepening within confirmed subjects). Research provenance:
     docs/design/RESEARCH_NOTES.md §9 (in-repo "epic" art + intrinsic integration), building on
     §7-§8. The three prior in-flight slices (discovery sparkle-spots, campfire rest, region
     ambience) are treated as MERGED ground truth and moved to Done — NOT re-proposed here.
     Ordered best-next-first. Every art slice is producible in-repo (Godot polygons/particles/
     shaders/tweens or procedural Python) and placeholder-fallback-safe; every learning slice
     stays inside the ALREADY-CONFIRMED numeracy/literacy subjects (format-deepening only, so
     none trip the CONFIRM gate) and is strictly bonus-only. Slices are independent unless a
     Sequencing note says otherwise. -->

### Ambient particle pass: drifting pollen and gentle fireflies per region
- **Goal:** Add soft, slow ambient particles that make the map feel alive — drifting pollen
  motes over the flower meadow, a few gentle fireflies near the forest edge and lake at the warm
  tint — reusing the region detection the ambience slice introduces so audio and particles share
  one region sense (cohesion, not a parallel system).
- **Design rationale:** NORTH_STAR pillar 1 (deepen the *existing* map across senses) and the
  owner's "epic art" mandate | research: `RESEARCH_NOTES.md` §9.1 — ambient particles (fireflies,
  pollen) are a native-Godot, no-imported-art way to make a scene feel alive; §7.1's gentle-
  feedback rule (few, soft particles — never a busy screen for a young player). Reusing the
  region-zone helper honors "make existing systems pay off before adding parallel ones."
- **Acceptance criteria:**
  - [ ] At least two ambient particle effects placed by region: soft drifting pollen over the
        flower-meadow region, a small number of gentle fireflies near the forest-edge/lake region
        — built with native `CPUParticles2D`/`GPUParticles2D` (no imported textures; a soft dot /
        `Gradient`-driven point is fine).
  - [ ] Particle emission is keyed to the map regions via the **same region-detection helper the
        in-flight region-ambience slice introduces** (shared function, not a second copy) — if
        that helper isn't yet a reusable static/shared function when this is built, refactor it to
        be one as part of this slice rather than duplicating region logic.
  - [ ] Deliberately sparse and slow (kid-audience §7.1): a handful of particles, low alpha, no
        flashing — atmosphere, not confetti.
  - [ ] Verifiable headlessly (particle nodes exist under the expected region/parent) AND via a
        live screenshot in the meadow and near the forest/lake.
  - [ ] Placeholder-fallback-safe and gameplay-neutral: no collision, no effect on combat/quests;
        purely visual.
- **Likely files touched:** `scenes/main/Main.tscn` (particle nodes per region, or a small
  `scenes/fx/AmbientParticles.tscn` instanced per region), the region-detection helper introduced
  by the ambience slice (`scripts/core/AudioManager.gd` or wherever it lands — extract/reuse),
  possibly `scripts/fx/` for a tiny emission-toggle script, `tests/` for any extracted region-
  detection logic.
- **Curriculum tie-in:** none — pure atmosphere/art.
- **Sequencing:** **Build after the region-ambience in-flight slice merges** — it deliberately
  reuses that slice's region-detection helper. Also lands after the day-warmth pass (particles
  read best against the warm tint). If ambience's region logic isn't reusable yet, this slice
  makes it so.
- **Status:** ready

### Living lake: animated water shimmer on the merged map's lake
- **Goal:** Make the just-built lake *move* — a slow, gentle shimmer/ripple over the lake's
  water tiles — so the map's centerpiece water feature feels alive instead of a flat blue patch,
  the single most "alive" upgrade to the merged region map.
- **Design rationale:** NORTH_STAR pillar 1 (deepen the *existing* lake, don't add water
  elsewhere) and the owner's "epic art" mandate | research: `RESEARCH_NOTES.md` §9.1 — animated
  water is a canonical low-fi "alive" cue and is native in Godot (a small `canvas_item` shader
  over the water region, or a tweened translucent `Polygon2D` overlay) with no imported art;
  §7.1's gentle rule (a soft shimmer, not a churning sea).
- **Acceptance criteria:**
  - [x] A gentle animated shimmer over the lake's water footprint (the existing water/deep-water
        tiles around tile ~(97,58)) — implemented as a small `canvas_item` shader sampling a
        scrolling gradient/sine, or a tweened low-alpha `Polygon2D`/`Sprite2D` overlay sized to
        the lake; no per-frame tile edits.
  - [x] The overlay sits under the player/NPC/prop y-sort layer so actors still draw over the
        water correctly; the existing water-collision (impassible) is unchanged.
  - [x] Slow and subtle (kid-audience): a calm shimmer, no strong motion or bright specular flash.
  - [x] Placeholder-fallback-safe: if a shader fails to compile the lake still renders as the flat
        water tiles (no crash); if a tweened overlay is used, it degrades to a static overlay.
  - [ ] Verifiable via a live screenshot at the lake (shimmer visible, actors draw correctly over
        it) plus a headless node-presence assertion. (Headless node-presence assertion done via
        `tests/lake_tests.gd`; the live screenshot check is left to the conductor's playtest pass.)
- **Likely files touched:** `scenes/main/Main.tscn` (one shimmer overlay node positioned over the
  lake), possibly `shaders/water_shimmer.gdshader`, a tiny `scripts/fx/` tween script if not a
  shader, `tests/atmosphere_tests.gd` (node presence).
- **Curriculum tie-in:** none — pure atmosphere/art.
- **Sequencing:** Independent of the learning slices; land after the three in-flight slices merge
  to avoid a `Main.tscn` conflict. Best after the day-warmth pass (shimmer reads with the tint).
  Lower priority than day-warmth (localized to the lake vs. whole-map mood) but a strong visual
  payoff.
- **Status:** done — see `docs/CURRENT_STATE.md`'s "Living lake" writeup. Implemented as a
  `canvas_item` shader (`shaders/water_shimmer.gdshader`) on a `ColorRect` in a new
  `scenes/fx/LakeShimmer.tscn`, instanced as `World/LakeShimmer` in `Main.tscn`. Covered by
  `tests/lake_tests.gd` (5 tests, registered in `tests/test_runner.gd`).

### Count-out-the-coins at the Merchant: bonus-only numeracy on purchase
- **Goal:** Extend the shipped Yarrow "pay the right coin" pattern to the Merchant's shop: when
  the child buys a weapon, offer an *optional*, bonus-only "count out the coins to match the
  price" beat — Grade 2 picks coins that add to the price, Grade 5 makes it with the fewest coins
  — so the shop the child already uses to spend coins becomes stealth numeracy practice, and the
  purchase always still completes.
- **Design rationale:** NORTH_STAR pillar 3 ("quests are playable arcs, not quizzes in disguise")
  AND pillar 1 (deepen the *existing* shop/economy loop, don't add a system) | research:
  `RESEARCH_NOTES.md` §9.2 — the canonical money-numeracy mechanic is "here is a price, hand over
  coins to make exactly that amount," with progression via constraints ("fewest coins"); this is
  intrinsic integration (the shop action *is* the practice), extending the §8.2 Yarrow reframe
  precedent already shipped.
- **Acceptance criteria:**
  - [ ] Reuses the **already-confirmed** G2/G5 numeracy competency (money/number sense) — a
        format change to the *existing* shop, NOT a new subject or a new quest, so it does **not**
        trip the subject-scope CONFIRM gate.
  - [ ] On a purchase in `ShopUI`, an optional coin-counting beat appears (Grade 2: choose coins
        that sum to the price; Grade 5: make the price with the fewest coins). The purchase
        **always completes** regardless — correct counting awards a bonus (a bonus flag/badge,
        matching the existing `award_quest_bonus` pattern, or a small extra coin, additive-only);
        wrong/skipped never blocks the buy, never penalizes, never scolds.
  - [ ] Strictly bonus-only and skippable: a child who just wants the weapon can dismiss the beat
        and still get it — the numeracy is a *bonus lane*, honoring the North Star core rule.
  - [ ] Grade 2 and Grade 5 framings both present (two-profile scaffolding) against the same
        confirmed competency; text is short/plain for G2 per `STYLE_GUIDE.md`.
  - [ ] Pure logic (does a chosen coin set sum to the price / is it the fewest-coins solution) is
        extracted into testable static functions and covered, mirroring
        `MeadowSlime.rolls_bonus_coin()`'s deterministic-test precedent.
- **Likely files touched:** `scripts/ui/ShopUI.gd` (+`.tscn`) for the coin-counting beat (or a
  small sibling UI reusing `LearningCheck`'s shape), `scripts/npcs/Merchant.gd` (flavor),
  `scripts/core/ContentDefinitions.gd` (prompt/flavor text), `scripts/core/GameState.gd` only if a
  new bonus flag is needed, a new `tests/coin_count_tests.gd` + `test_runner.gd`,
  `docs/design/CURRICULUM_MAP.md` (note the new stealthy numeracy beat, same not-CONFIRM-gated
  reasoning as the Yarrow reframe row).
- **Curriculum tie-in:** **Directly deepens** the confirmed G2/G5 numeracy subject (money/number
  sense) at the Merchant — same subject, stealthier in-fiction format. NOT CONFIRM-gated.
- **Sequencing:** Independent of the three in-flight slices (touches shop/UI code, not `Main.tscn`
  geometry) — can be built any time. Highest-value learning slice: it turns an existing daily
  action (buying gear) into practice, exactly the owner's "learning out the wazoo" ask.
- **Status:** done

### Elder's "what did you notice?": bonus-only reading comprehension on codex/keepsake flavor
- **Goal:** After the child earns a new "Creatures met" entry or a keepsake, let the Elder offer
  ONE optional, friendly reading-comprehension question drawn from the flavor text the child just
  read (Grade 2: recall one plain fact; Grade 5: infer meaning / a word's sense) — so the reading
  the game already asks the child to do becomes the assessment, bonus-only, no new quiz screen
  bolted on.
- **Design rationale:** NORTH_STAR pillar 5 (permanent world-knowledge already exists as the
  codex/keepsakes — make *reading it* pay off) AND pillar 3 (fiction carries the skill) |
  research: `RESEARCH_NOTES.md` §9.2 — reading comprehension can be assessed unobtrusively *while
  the child reads in-fiction text* (intrinsic integration), which maps directly onto the flavor
  text the codex/keepsake systems already show; uses the already-confirmed literacy competency.
- **Acceptance criteria:**
  - [ ] Reuses the **already-confirmed** literacy competency (word choice / comprehension) — a new
        stealthy *format* over existing flavor text, NOT a new subject or a 5th quest, so it does
        **not** trip the subject-scope CONFIRM gate.
  - [ ] Triggered optionally by talking to the Elder after a new codex/keepsake entry is earned;
        the Elder asks one short, friendly question about the flavor text just unlocked. Grade 2:
        recall a plain stated fact; Grade 5: light inference or a word's meaning.
  - [ ] Strictly bonus-only: a correct answer awards a bonus (matching the existing
        `award_quest_bonus`/badge pattern); wrong or skipped never blocks anything, never
        penalizes — the Elder responds warmly either way. The child can decline the question
        entirely and lose nothing.
  - [ ] Questions are authored per confirmed codex/keepsake entry (data-driven, e.g. an optional
        `question`/`answer` field alongside `CREATURE_FACTS`/`KEEPSAKE_FACTS`), so adding a future
        creature/keepsake can add its own bonus question without new mechanics.
  - [ ] Grade 2 and Grade 5 framings both present; G2 text short/plain per `STYLE_GUIDE.md`.
  - [ ] Any answer-checking logic is a pure, tested function; reuses `LearningCheck` or its shape
        rather than a new bespoke UI.
- **Likely files touched:** `scripts/npcs/Elder.gd` (offer the optional question when a new codex/
  keepsake entry exists), `scripts/core/ContentDefinitions.gd` (`CREATURE_FACTS`/`KEEPSAKE_FACTS`
  gain an optional bonus-question/answer field), `scripts/ui/LearningCheck.gd` (reuse), possibly
  `scripts/core/GameState.gd` (track which entries' bonus question was answered, so it isn't re-
  asked — save-safe via `.get()`), a new `tests/comprehension_tests.gd` + `test_runner.gd`,
  `docs/design/CURRICULUM_MAP.md` (note the reading-comprehension bonus lane, not-CONFIRM-gated).
- **Curriculum tie-in:** **Directly deepens** the confirmed literacy subject (comprehension/word
  choice) via the existing codex/keepsake text — same subject, intrinsic-integration format. NOT
  CONFIRM-gated.
- **Sequencing:** Depends on the "Creatures met" codex and keepsake systems (both merged) — no
  dependency on the three in-flight slices. Touches NPC/UI/content code, not `Main.tscn` geometry,
  so no map-merge risk. Build after the Merchant coin-counting slice (that one deepens the more
  frequently-used loop first).
- **Status:** ready

### Palette-lock pass: codify gen_tileset.py colors as one documented shared palette
- **Goal:** Turn the tileset's colors into a single documented, shared palette (per pixel-art
  ramp discipline) so future tiles, polygon props, and particles all draw from one harmonized set
  — the cohesion foundation that makes every later art slice look like one world instead of
  drifting ad-hoc RGBs.
- **Design rationale:** NORTH_STAR pillar 1 ("cohesion over volume" — a shared palette is
  literally the cohesion lever) and the owner's "epic art" mandate | research:
  `RESEARCH_NOTES.md` §9.1 — palette discipline (few ramps, brightness up / saturation down at
  the bright end, hue-shifted) is the single strongest cohesion lever, and the constraint *is* the
  cohesion; `docs/art/STYLE_GUIDE.md`'s new one-pager (lever 1).
- **Acceptance criteria:**
  - [ ] The `gen_tileset.py` colors are consolidated into a single named palette constant (a few
        value ramps following §9.1: brightness up, saturation eased at the bright end, gentle hue
        shift) that the tile-generation functions draw from, with no visual regression to the
        already-painted map (regenerating the tileset produces the same or a deliberately gentler,
        more-harmonized result — verify the map still reads identically in a screenshot).
  - [ ] The palette is documented (in `STYLE_GUIDE.md` or a short comment block in
        `gen_tileset.py`) as the source of truth new procedural art / polygon props should sample
        from, so future colors are picked from the palette, not invented.
  - [ ] Purely a refactor of color definitions + docs: no new tiles required, no gameplay change,
        no `Main.tscn` edit (the tileset PNG regenerates to the same atlas layout/coordinates so
        every painted cell keeps its meaning — the same hard rule `gen_tileset.py` already honors).
  - [ ] If any tile color shifts at all, it is a *gentle* harmonization only, screenshot-verified
        against the current map to confirm it still reads bright and cohesive for the kid audience.
- **Likely files touched:** `assets/sprites/tiles/gen_tileset.py` (palette constant + refactor),
  `assets/sprites/tiles/placeholder_tileset.png` (regenerated), `docs/art/STYLE_GUIDE.md` (record
  the palette). No scene/gameplay files.
- **Curriculum tie-in:** none — pure art-foundation/systems.
- **Sequencing:** Independent of everything (touches only the tileset generator + docs, not
  `Main.tscn`). Lowest priority of the art slices because it's foundational/invisible rather than
  an immediate visible "wow," but it makes every future art slice more cohesive — a good pickup
  when a visible slice is blocked on a merge.
- **Status:** ready

### Character-sprite polish pass: replace one key placeholder-polygon actor with a generated sprite
- **Goal:** Replace ONE key placeholder-polygon actor (Mossy the pet is the best first
  candidate — a flat polygon blob) with a proper small generated sprite honoring the style guide,
  proving the sprite-upgrade path for the remaining polygon actors (NPCs, slimes) without a big-
  bang art dump.
- **Design rationale:** NORTH_STAR pillar 1 (one excellent thing before a second — upgrade one
  actor, prove the path) and the owner's "epic art" mandate | research: `RESEARCH_NOTES.md` §9.1
  — strong silhouette + limited palette + 1px outline carry readability at small sizes; the
  in-repo production options are the documented AI-source normalization pipeline OR richer hand-
  authored Godot polygon/shape art (both already precedented). `docs/art/STYLE_GUIDE.md`.
- **Acceptance criteria:**
  - [ ] Exactly ONE actor upgraded (Mossy recommended) from placeholder polygon to a proper small
        sprite: either normalized through the documented pipeline
        (`docs/art/ASSET_NORMALIZATION_PIPELINE.md`, with source prompt saved) OR a richer hand-
        authored polygon/`AnimatedSprite2D` build — whichever the implementer can produce in-repo.
  - [ ] Honors `STYLE_GUIDE.md`: transparent PNG (if a sprite), clear silhouette, limited palette
        drawn from the shared palette (see the palette-lock slice), readable at game scale, feet/
        pivot aligned like the existing actors.
  - [ ] Placeholder-fallback-safe: the scene still loads if the new art is missing (keep the swap
        localized to one scene; no crash on a missing texture).
  - [ ] No behavior change — Mossy's follow-AI/stats are untouched; this is art only.
  - [ ] Verifiable via a live screenshot (Mossy reads clearly next to the player) and, if a
        pipeline asset, a `validate.py` pass on its manifest.
- **Likely files touched:** `scenes/pets/Pet.tscn` (swap the polygon `Body` for the sprite), a new
  asset under `assets/sprites/` (+ manifest/source if pipeline-produced), possibly a source prompt
  under `assets/source/prompts/`. No `Main.tscn` or logic changes.
- **Curriculum tie-in:** none — pure art.
- **Sequencing:** Independent of every other slice (localized to `Pet.tscn` + assets). Filed LAST
  of this pass: it is the heaviest and least cohesion-critical art work (one actor's fidelity vs.
  whole-map mood), and it benefits from the palette-lock slice landing first so the sprite draws
  from the shared palette. A good candidate once the cheaper atmosphere slices have shipped.
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

<!-- Moved from Ready in the fourth pass (2026-07-01): the prior pass's three slices are now
     merged/in-flight ground truth (see this pass's Planning baseline), and the Yarrow numeracy
     reframe shipped. -->

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
