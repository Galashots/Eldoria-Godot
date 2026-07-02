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

## 7. Live web research for the second expansion pass (2026-07-01, orchestrator refill)

Gathered while refilling the backlog after the first expansion cycles shipped (Legendary
weapon, landmark props). Same caveat as §6 applies.

### 7.1 Game feel / "juice" — hit feedback

- ["Where Does Game Feel Come From: Flash, Shake, Floating Text, Sound, Particle Feedback" —
  BetterLink Blog](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) and
  ["Game Feel: A Beginner's Guide" — Game Design Skills](https://gamedesignskills.com/game-design/game-feel/),
  plus ["7 Game Feel Tricks" — Dawnosaur](https://dawnosaur.substack.com/p/7-game-feel-tricks-to-improve-your) —
  the cheapest, highest-impact hit feedback is a brief **white flash** on the struck sprite
  (~50-100ms), optionally a short **hit-stop** (~0.05-0.1s freeze) and a *subtle* camera
  shake (0.1-0.3s, small amplitude). These come from the canonical "Juice it or lose it"
  (Jonasson/Purho, GDC 2012) lineage.
- Counterpoint: ["The Juice Problem" — Wayline](https://www.wayline.io/blog/the-juice-problem-how-exaggerated-feedback-is-harming-game-design) —
  over-juicing (big shakes, heavy flashes) harms readability and can overwhelm; keep it
  subtle. **Especially important for a Grade 2/5 audience** — a gentle flash reads as "I hit
  it!" without the screen-thrash that would distract a young player.
- **Use for this project:** a small, reusable **hit-flash** on `HealthComponent` damage
  (flash the owner's sprite white briefly) is the smallest game-feel slice — it deepens the
  existing M2 combat (readability of a landed hit) without a new system, and directly
  supports the deferred Elder Slime mini-boss's telegraph. Skip screen shake for now (the
  "juice problem" caution + young audience) unless a playtest asks for it.

### 7.2 Enemy respawn / repeatable faucet pacing

- ["Respawning On-Map Enemies" — The Official RPG Maker Blog](https://www.rpgmakerweb.com/blog/respawning-on-map-enemies) —
  the two standard patterns are **map-based** (enemies return only after the player leaves &
  re-enters the area — lets a player clear an area and explore safely) and **time-based**
  (enemies return after a delay — keeps an area alive/dangerous and *lets a player grind if
  they choose*). Respawn cadence is the direct control over how grindy an area feels.
- **Use for this project:** this is the fix for the faucet bottleneck flagged in
  `GEAR_AND_ECONOMY.md` (3 non-respawning Meadow Slimes = ~3 coins/session). Eldoria has one
  persistent zone with no map transitions, so **time-based** is the fit: a gentle respawn
  cadence at each slime spawn point makes the coin faucet *repeatable* without forcing a
  grind. Keep the cadence slow and the count capped (respawn to at most the original 3) so it
  stays gentle for a young audience — do NOT make the zone feel crowded or dangerous. Cleanest
  implementation is a small standalone `Spawner` node (disjoint from `MeadowSlime.gd`), not a
  rewrite of the slime.

### 7.3 Collection / codex loops (permanent-progress payoff)

- ["Monster Compendium" — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Main/MonsterCompendium) —
  a bestiary/compendium filled by *encountering or defeating* creatures is a classic,
  low-cost collection loop; examples (Kingdom of Loathing's "Monster Manuel", Kirby 64's
  monster cards) pair each entry with a short friendly factoid, and a completed compendium
  can itself be a soft reward. ["Creating Monsters: Three Ingredients of Great Bestiaries" —
  The Ugly Monster](https://medium.com/theuglymonster/creating-monsters-the-three-ingredients-of-great-bestiaries-6bc017a51436) —
  a good entry gives a creature a bit of character/story, not just stats.
- **Use for this project:** directly serves NORTH_STAR pillar 5 ("every short session yields
  permanent progress — world knowledge, a keepsake, a codex entry"). A tiny **"Creatures
  met"** list in the character panel — populated the first time the player defeats each
  monster type, with a one-line friendly factoid — turns combat into permanent, collectible
  world-knowledge. Bonus-only and non-punitive by construction (you only ever *gain* entries).
  Keep it text-only (no new art) and reuse the existing character-panel UI.

### General caveat (applies to §7 as §6)

Same as §6: these are secondary-source web summaries; treat timings/percentages as tunable
starting ranges, confirm feel in-engine.

## 8. Live web research: kid-stickiness without dark patterns + stealth-learning (2026-07-01)

Gathered by `game-architect` for the post-map/post-Elder-Slime backlog pass. Focus: what
makes a 2D RPG sticky and *joyful* for 7–11-year-olds **without** dark patterns, and what
makes stealth-learning actually work (woven into mechanics vs. bolted-on quizzes). Same
general caveat as §6/§7 — secondary-source summaries, tune in-engine. Planned assuming the
epic map pass (region-distinct world: village green / flower meadow / forest edge / lake /
rocky border) and the Elder Slime mini-boss have **both** merged.

### 8.1 Session-end that respects bedtime (disengagement-friendly design)

- ["Exploring the Potential of Disengagement-Friendly Game Design to Support Children's Exit
  from Play Sessions" — Proceedings of the 2026 CHI Conference](https://dl.acm.org/doi/10.1145/3772318.3790564) —
  a research prototype ends a child's session with an in-fiction **bedtime screen**: the
  player puts their character to sleep after the adventure, the game fades to black and shows
  "Good Night," and offers **no further interaction**. Findings: implicit, diegetic
  progress-feedback (a bedtime routine) is *easier for children to understand* than an
  abstract progress bar, helps them **anticipate** the end of a session, and gives a parent a
  shared story ("your hero is tired now") to explain why play is over. This is the ethical
  inverse of a "one more thing" retention hook — it engineers a *satisfying stopping point*,
  not an open loop.
- ["Daily Quests or Daily Pests? The Benefits and Pitfalls of Engagement Rewards in Games"
  (ResearchGate)](https://www.researchgate.net/publication/365003534_Daily_Quests_or_Daily_Pests_The_Benefits_and_Pitfalls_of_Engagement_Rewards_in_Games)
  and ["Dark patterns" — Better Internet for Kids, European Union](https://better-internet-for-kids.europa.eu/en/dark-patterns) —
  daily/streak rewards become **dark patterns** the moment missing a day *removes* a benefit
  or creates FOMO/urgency; temporal dark patterns exploit fear-of-missing-out to extend
  sessions past what the player wanted. The ethical form is an **optional bonus with no
  penalty for missing it** — never a mandatory streak, never loss-framed, never social
  pressure.
- **Use for this project:** two distinct, small, ethical slices. (a) A **diegetic
  session-end "rest" beat** — a cozy in-fiction moment (a campfire/inn/bedroll) the child can
  choose that visibly banks the session's progress and reads as "a good place to stop," the
  opposite of a cliffhanger hook; strongly aligned with NORTH_STAR pillar 5 (every session
  yields permanent progress). (b) If any session-start bonus is ever built, it must be
  **additive-only and penalty-free** (a small gift *for showing up today*, never a streak you
  can break) — this is the same bonus-only/non-punitive rule the curriculum already follows,
  applied to engagement. Both must avoid the temporal-dark-pattern failure mode above.

### 8.2 Intrinsic integration — learning woven into mechanics, not bolted-on quizzes

- ["The Stealth Learning Guide: Games That Teach…" — Screenwise](https://screenwiseapp.com/guides/educational-games-that-don-t-feel-like-school) —
  the core principle is **mechanics-first learning: "the work is the game. To win, you have
  to master the system."** The named failure mode is the reward-for-work split ("solve five
  math problems to jump over the pit") — the game becomes a bribe wrapped around a quiz.
  Better patterns: (1) the skill is *inherent to progression* (to build the thing you want,
  you must understand the underlying idea); (2) **natural failure feedback** — the world
  visibly shows *where* you went wrong (Poly Bridge highlights the over-stressed beam) rather
  than marking an answer "wrong"; (3) **graduated complexity** — start simple, scale up as
  competence grows; (4) works best with a **co-pilot** (a parent asking "how did you do
  that?"), so design should invite reflection, not just score it.
- ["Maximizing learning without sacrificing the fun: Stealth assessment" — Shute et al.,
  JCAL 2020 (PDF)](https://myweb.fsu.edu/vshute/pdf/JCAL2020.pdf) and ["'Stealth' Learning
  Games" — EduGamery](https://edugamery.com/educational-games-portfolio/stealth-learning-games/) —
  stealth assessment is woven *invisibly into the fabric* of the game: infer understanding
  from in-fiction actions (did the player pay correct change? pick the safe route?) instead
  of asking outright — exactly the "evidence-centered" direction `CURRICULUM_MAP.md` already
  names as its future bridge.
- **Use for this project:** the current two-choice `LearningCheck`/`CombatQuestion` quizzes
  are the *bolted-on* pattern this research warns against (kept deliberately, by user
  decision). The nearest **honest** improvement that stays inside the confirmed subjects and
  the bonus-only rule is to make one existing check **stealthier** — e.g. a numeracy check
  expressed as an *in-fiction action* (pay the right number of coins, pick the pouch that
  weighs more) rather than an abstract "which is bigger?" prompt. This deepens an existing
  quest (cohesion) instead of adding a new subject (which is CONFIRM-gated). **Do not** add
  new subjects/quizzes; make the fiction carry the skill. NOTE: converting a check's *format*
  reuses the already-confirmed numeracy/literacy competencies, so it does **not** trip the
  subject-scope CONFIRM gate — but changing *which subject* a check exercises would.

### 8.3 Discovery / secret-finding as an intrinsic joy loop

- ["Unlocking Discovery in Game Design" — Number Analytics](https://www.numberanalytics.com/blog/ultimate-guide-to-discovery-in-game-design)
  and ["8 Metroidvanias That Hide Their Greatest Content Behind Optional Exploration" —
  DualShockers](https://www.dualshockers.com/metroidvanias-hide-greatest-content-behind-optional-exploration/) —
  discovery is a fundamental motivator: uncovering a hidden thing produces a self-contained
  sense of accomplishment, and **rewarding curiosity** (a secret grove, a sparkle spot, an
  optional-boss gift) is one of the strongest, cheapest engagement drivers. Crucially,
  optional exploration **rewards the curious without punishing those who miss it** — a
  perfect fit for the bonus-only rule.
- ["6 Most Satisfying Gameplay Loops" — Featured.com](https://featured.com/questions/satisfying-gameplay-loop-addictive-games)
  and the Zelda: BotW well-being study ([PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12357126/)) —
  the Zelda-like loop (clear goals like shrines/Korok seeds + freedom to explore) fosters
  *autonomy, calm, mastery, and a sense of purpose* — the healthy inverse of compulsion; the
  satisfaction comes from **discovery and meaningful progression**, not from streaks or
  timers.
- **Use for this project:** the newly-merged region-distinct map is the natural home for a
  tiny **discovery slice** — a handful of hidden "sparkle spots" (a shimmering tuft in the
  flower meadow, a hollow at the forest edge) that, when found and touched, grant a small
  bonus (a coin, a codex-style "place discovered" entry, or a keepsake) **and never punish
  missing them**. This deepens the *existing* new map (cohesion over volume — not a new
  biome) and feeds pillar 5 (permanent world-knowledge). Reuse the existing `Collectible`/
  codex machinery; keep it text/placeholder-art only.

### 8.4 Collection / completion psychology (keepsakes, not stats)

- ["6 Most Satisfying Gameplay Loops" — Featured.com](https://featured.com/questions/satisfying-gameplay-loop-addictive-games) —
  meaningful *progression* (new items, a filling collection, uncovering something hidden) is
  what makes a loop satisfying; the payoff can be "just the satisfaction of uncovering
  something," not a stat boost. Combined with §7.3's bestiary/compendium finding, this argues
  the game's collection loops (the shipped "Creatures met" codex; a future "places
  discovered" list) are strong *because* they are permanent and non-punitive, independent of
  power.
- **Use for this project:** a **boss keepsake** — when the Elder Slime mini-boss is defeated,
  grant a **cosmetic/keepsake trophy** (a codex/keepsake entry, e.g. "Elder Slime's Dewdrop")
  rather than only a stat. NORTH_STAR pillar 5 explicitly lists "a keepsake/cosmetic" as a
  valid session payoff, and pillar 3 wants a *visible consequence*. A keepsake makes the
  mini-boss memorable without a power-creep arms race — deepening the just-shipped codex and
  mini-boss systems together (cohesion) instead of adding a parallel reward track.

### General caveat (applies to §8 as §6/§7)

Same as prior sections: secondary-source web summaries (plus two peer-reviewed papers, §8.1/
§8.2), not primary design authority. Treat specifics as tunable starting points; the
bonus-only, non-punitive, CONFIRM-gated rules of this project override any source that would
push toward streaks, penalties, new subjects, or compulsion loops.
