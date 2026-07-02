# Current State

## Status

Milestones 1 through 14 are complete and merged: the PR branch-sync docs rule, the `docs/design/` north-star doc set, the bonus-only realignment of the Elder/Mira/Finn learning checks, the Python asset normalization pipeline (`tools/asset_pipeline/`), and a proof pass that normalizes one ChatGPT test render through the pipeline and displays it on the player in place of the flat-color placeholder.

The player sprite is now profile-aware and direction-aware: `Player.gd` swaps its texture based on `GameState.selected_profile` and the player's current movement direction. Both Grade 5 Adventurer and Grade 2 Mage have production 5-direction idle sets (south/south-east/east/north-east/north, generated from user-approved ChatGPT designs and normalized through the pipeline). The Mage set was generated as a single 5-panel sheet in one ChatGPT response (rather than 5 separate generations like the Adventurer) and cropped into a shared source image addressed by grid cell per direction — proving that approach also works. All 8 facings are now live: west/south-west/north-west mirror east/south-east/north-east via `flip_h`, matching the 5-render-plus-mirroring convention. The player's `Body` node is now an `AnimatedSprite2D` (was a plain `Sprite2D`), with one `SpriteFrames` resource per profile built in code from the existing idle textures (each direction is a single-frame animation, e.g. `idle_s`) — this is a zero-visual-change engine migration that gets the architecture ready for real multi-frame walk animations later, since adding walk frames will just mean calling `add_frame()` more times on the same `SpriteFrames`. A hidden, empty sibling `Armor` `AnimatedSprite2D` node also now exists, reserved for a future paper-doll equipment layer; no armor art exists yet, so `Armor` stays invisible. Walk-cycle animation is now live for both characters: each direction has a 4-frame loop (idle -> walk1 -> idle -> walk2, reusing the existing idle pose as the neutral "passing" frame rather than commissioning a full frame-by-frame cycle) that plays automatically while the player is moving, and reverts to the static idle pose the instant movement stops. Tier 1 (Leather) armor art now exists for both characters as full replacement idle sprite sets (see `docs/design/ARMOR_TIERS.md`), normalized through the same pipeline as base body art, and is now reachable in-game: completing all three existing quests (Elder, Mira, Finn) auto-equips it via `GameState.equipped_armor_tier`, `Player.gd` swaps the player's `SpriteFrames` to the tier1 set, and the character panel's equipment line shows "Equipment: Leather Armor". There is no manual equip/unequip UI (auto-equip only), and armored walking shows a static pose since no tier1 walk-cycle art exists yet.

Local save/load now exists: `GameState` autosaves to `user://savegame.json` (JSON via `FileAccess`/`JSON`) on every profile/quest/item/armor change, and loads it in its own `_ready()` — before any other scene node's `_ready()` runs — so the game auto-resumes silently on relaunch (the profile selector and already-collected world pickups self-hide exactly as they already did for a fresh, no-save boot; no changes were needed to `ProfileSelect.gd`/`Collectible.gd`/`HUD.gd` to make this work). The character panel has a mouse-only "Reset Progress..." button (no keyboard shortcut) that requires an explicit second confirmation click before calling `GameState.reset_progress()`, which clears the save file and reloads the scene fresh. `reset_progress()` is composed from `reset_state()` (clears data + deletes the save file) plus a conditional scene reload, split apart so the state-clearing half can be exercised headlessly without a loaded scene.

A small custom GDScript test suite now exists (`tests/`, see "How to run the GDScript test suite" below) covering `GameState`'s quest lifecycle, item/quest wiring, badge tracking, the Tier 1 armor auto-grant (order-independence, fires-once), and the save/load/reset round trip. Building it caught two real, non-obvious bugs, both now fixed: (1) `collected_items`' counts silently became floats after a save/load round trip, since `JSON.parse_string()` returns all numbers as float and a `Dictionary`'s values have no static type to auto-coerce them back — `load_game()` now explicitly casts each loaded count to `int`. (2) A signal connected to a **lambda** on a `RefCounted` object did not reliably fire on this Godot 4.7 build, even though the exact same signal correctly reached a **named** bound method — every probe in the test suite uses a named method for this reason; see the note in `tests/game_state_tests.gd` for the diagnosis.

A fourth quest now exists: **Yarrow the Healer** (`QUEST_YARROW_SILVERLEAF`), gated behind Finn's completion, mirroring the existing Elder/Mira/Finn shape exactly (fetch item, two-choice profile-specific learning check, bonus-only completion). Deliberately scoped narrow rather than sprawling into a new NPC archetype/subject/biome, per `docs/design/NORTH_STAR.md`'s explicit "resist feature equity across many NPCs/biomes" guidance and `docs/design/CURRICULUM_MAP.md`'s unconfirmed subject-scope flag: Yarrow stays in the same village hub, continues the same linear gate chain (Elder → Mira → Finn → Yarrow), and reuses the already-confirmed numeracy (G2: coin comparison) and literacy (G5: word choice) subjects rather than introducing a new one. The Tier 1 armor grant now requires all **four** quests, not three — a deliberate design call (not forced by the code) reasoned through explicitly: it's backward-compatible for existing saves (armor never un-grants once earned, since `_check_and_grant_tier1_armor()` early-returns once `equipped_armor_tier > 0`), and keeps "you're geared up" meaning "you finished everything the village has to offer" rather than freezing at the original three.

**World/map foundation (M1 of the Phase 2 roadmap): done.** The flat single-screen
`World/Floor` Polygon2D + one `Obstacle` in `scenes/main/Main.tscn` are replaced with a
`World/Ground` `TileMapLayer` over a bigger, tiled, collidable zone (160x100 tiles,
2560x1600px), using a bootstrap 4-tile placeholder tileset (grass, dirt path, water, rock —
see "Implemented files" below) to prove `TileMapLayer` + `TileSet` collision + camera limits
end to end before real tile art exists. Water and rock tiles carry a `TileSet` physics-layer
collision polygon (impassible); grass and path are walkable. `World.y_sort_enabled` is on,
as is `y_sort_enabled` on the player and all 4 NPCs, so vertical draw order now follows
position. The Player's existing `Camera2D` now has `limit_left/top/right/bottom` set to the
map bounds and `position_smoothing_enabled` on, so the camera stops at the zone edges
instead of showing empty space and follows the player smoothly instead of snapping. The
existing 4 NPCs (Elder, Mira, Finn, Yarrow), their 4 collectibles, and the player spawn are
repositioned into the new zone, connected by dirt-path tiles, with a lake and two small rock
outcrops as impassible terrain features so the collision system has something to prove
itself against (previously only one brown obstacle rectangle existed). The 4-quest chain,
save/load, and equip system are unchanged and were confirmed still working live (Elder's
full quest — item pickup, learning-check UI, bonus badge, HUD advance to Mira — was played
through end to end against the new map; the other 3 quests share identical code paths and
are already covered by the automated test suite). Save-schema versioning was folded into
this milestone per the Phase 2 plan: `GameState.save_game()` now writes a `"version": 1`
field and `load_game()` calls a `_migrate(data)` step (currently a no-op — old un-versioned
saves and v1 have the same shape) so future schema growth (combat/inventory/pets/farm) can
migrate old saves forward instead of crashing on load.

**Combat + first monster (M2 of the Phase 2 roadmap): done.** Real-time, movable
hack-and-slash (Stardew-style, not a battle-transition screen) arrives via the
component architecture the Phase 2 plan called for: `HealthComponent`,
`HitboxComponent`/`HurtboxComponent` (`scripts/core/combat/`), matched by group ("hitbox"/
"hurtbox") rather than a dedicated physics layer, since everything in this project already
defaults to layer/mask 1 and that's proven enough at this scale. The player has a new
`attack` input action (Space or left click) that swings a brief hitbox in the facing
direction (`Player._swing_attack()`), damaging anything with a matching hurtbox; a
`HurtboxComponent` never damages its own owner (a same-parent check), which matters because
an enemy's own contact-damage hitbox and its hurtbox occupy the same space. The first
monster, **Meadow Slime** (`scripts/enemies/MeadowSlime.gd`/`.tscn`), is deliberately the
lowest-stakes possible enemy for a Grade 2/5 audience: slow wander/chase AI within an aggro
radius, 3 hp, 1 contact damage on touch (gated by a brief hit-immunity window so standing in
it doesn't melt hp every physics frame). Real art landed the same session, generated via
ChatGPT from the prompt in `docs/design/MONSTER_CONCEPTS.md` and normalized through
`tools/asset_pipeline/` into `assets/sprites/enemies/meadow_slime_idle.png` (a single
static idle pose - the slime doesn't turn to face the player). Three
instances are placed in the M1 zone away from the quest lines. The player keeps using
`GameState.player_hp` as its single source of truth (now wired to real damage via
`GameState.take_player_damage()`/`heal_player_to_full()`) rather than getting its own
`HealthComponent`, since that field already existed and is already saved; enemies get the
new component since they need no persistence. Death is non-punitive per the North Star: at
0 hp the player teleports back to wherever they started the scene (captured once in
`Player._ready()`), heals to full, and gets a brief friendly dialogue line — no game over
screen, no penalty.

The user's requested damage-multiplier idea is implemented as a stacking, decaying combat
streak: landing a hit while no question is on a ~12s cooldown pops a quick profile-aware
2-choice numeracy question (`scenes/ui/CombatQuestion.tscn`/`.gd` - a new, deliberately
separate scene from `LearningCheck`, since it has zero quest coupling and dismisses itself
the instant an answer is picked rather than showing a lingering completion line). A correct
answer bumps `GameState.combat_streak` (capped at 3), giving a `1 + streak*0.5` damage
multiplier (1x/1.5x/2x/2.5x) applied to the *next* swing's damage, not retroactively to the
hit that triggered the question. The streak decays by 1 every ~8s without a further correct
answer. A wrong answer never reduces the streak or otherwise penalizes - bonus-only, same
rule as every other learning check in this project. This state is deliberately **not**
persisted (`GameState.save_game()`'s dict is untouched) since it's a moment-to-moment combat
feel mechanic, not saved progress; `reset_state()` clears it anyway for hygiene. The HUD
gained an "On Fire! x1.5"-style label (hidden at streak 0) and an "HP: 5/5" readout, since
this is the first milestone where player hp is actually meaningful to see.

No EventBus yet, per the "grow feature-by-feature" decision - every new signal here is a
direct connection, same as the existing NPC-to-UI wiring. Two real bugs were caught and
fixed during live verification (both now covered structurally, not just patched): a
`HurtboxComponent`'s exported `health: HealthComponent` node reference did not reliably
resolve from a raw `NodePath("...")` literal written directly into `.tscn` text (fixed by
auto-discovering a sibling node named "HealthComponent" in `_ready()` instead of relying on
a typed node export); and setting an `Area2D`'s `monitorable`/`monitoring` directly from
inside a hit-reaction callback raised a Godot engine error ("Function blocked during in/out
signal") - both now go through `set_deferred()`, matching the existing pattern in
`Player.gd`'s equip-armor code elsewhere in this codebase. The GDScript test suite grew by 4
tests covering the new pure-logic combat math (streak stacking/capping, the wrong-answer
no-penalty rule, the question cooldown, player damage/heal/death signal firing) - see "How
to run the GDScript test suite" below, now 13 tests total.

**Gear, rarity, coins & shop (M3 of the Phase 2 roadmap): done.** Deliberately a **tight
vertical slice** rather than the full "gear/rarity/inventory + shop" surface the milestone
name implies, per `docs/design/NORTH_STAR.md`'s "cohesion over volume" pillar: weapons only
(one gear slot), one rarity axis, one vendor NPC, manual equip — see
`docs/design/GEAR_AND_ECONOMY.md` for the locked rarity list and price scale. The first real
stats `.tres` (flagged as likely in M2's writeup above) lands here: `GearDefinition.gd`
(mirroring `ItemDefinition.gd`) backs the weapon roster under `data/gear/` (Worn Dagger/Common/
+1, Iron Sword/Uncommon/+2, Oakheart Blade/Rare/+3 shipped with M3; the Legendary Dawnbringer
Blade/+4/30 coins was added later as the first autonomous expansion-loop slice — an
aspirational top-of-shop coin sink, see `docs/design/GEAR_AND_ECONOMY.md`). Meadow Slimes now drop exactly 1 coin on
death (`CoinPickup.tscn`/`.gd`, mirroring `Collectible.gd`), tying the new economy directly to
the M2 combat loop rather than to quest rewards. A new `Merchant` NPC (`scripts/npcs/
Merchant.gd`/`.tscn`) opens a `ShopUI` panel on interact — no dialogue box, since the shop
panel itself is the interaction surface — listing every `GearDefinition` with its rarity
color, damage bonus, and a Buy button that disables once owned or unaffordable. Equipping an
owned weapon happens in the character panel (not the shop), which gained a `Coins:` readout
and an owned-weapons list with per-weapon Equip buttons; `Equipment:` now lists armor and
weapon together. `Player._swing_attack()`'s damage formula gained one term
(`GameState.get_equipped_weapon_bonus()`), so gear and the M2 math-streak multiplier stack
multiplicatively — live-verified via `game_eval` (base 1 + iron_sword's +2 = 3 damage on the
real `AttackHitbox`, matching the formula exactly). Save schema bumped to version 2
(`coins`/`owned_gear`/`equipped_weapon`); `_migrate()` stays a no-op since `load_game()`
already reads every field via `.get()` with an in-code default, so old saves missing these
keys load cleanly. No EventBus, no sell-back, no armor-as-buyable-gear — all explicitly
deferred in `GEAR_AND_ECONOMY.md`, not forced by the code. Test suite grew to 16 (3 new:
coin overspend guard, buy/ownership idempotency, equip-requires-ownership + damage bonus).

**Meadow Slime bonus-chance coin drop (expansion backlog): done.** A tight, additive-only
follow-up to M3's flat 1-coin drop, per `docs/design/GEAR_AND_ECONOMY.md`'s new "Bonus drop
rule": `MeadowSlime.gd` still always spawns its guaranteed 1-coin `CoinPickup`, and now also
rolls a small exported `bonus_coin_chance` (default 0.12 / 12%) for exactly one *additional*
coin on top — the guaranteed drop is never reduced or replaced, honoring the bonus-only rule
that governs every reward system in this project. The roll is a pure static function,
`MeadowSlime.rolls_bonus_coin(chance, roll)`, deliberately separated from the engine's
`randf()` call so it's deterministically unit-testable (both the "misses" and "hits"
branches) without a scene tree or RNG seeding. Scoped to a single exported var on
`MeadowSlime.gd` rather than a new loot-table framework, since there's still only one enemy.
Test suite grew to 17 (1 new: the bonus-roll boundary/hit/miss cases).

**Pets (M4 of the Phase 2 roadmap): done.** A deliberately narrow first slice — one species,
follow-only AI, no pet combat — per `docs/design/NORTH_STAR.md`'s "cohesion over volume"
pillar; see `docs/design/PETS.md` for the locked rules. `PetDefinition.gd` (mirroring
`GearDefinition.gd`) backs the pet roster under `data/pets/`; the first and only pet is
**Mossy** (`data/pets/mossy.tres`, Rare, +2 Max HP), with placeholder polygon art (a mint/teal
blob with a leaf and eyes) in `scenes/pets/Pet.tscn`. `Pet.gd` is a `CharacterBody2D` with
follow-only AI (no `HealthComponent`, no combat): it moves toward the player at speed 220
whenever it's more than 24px away and stops inside that ring, since the player moves at 160.
Unlocking reuses the exact same gate as the Tier 1 armor grant — completing all four village
quests — via `GameState._check_and_grant_first_pet()`, called from `complete_quest()`; it
grants Mossy once, auto-equips it, and heals the player by the bonus amount so the new max hp
arrives full rather than leaving the player visually damaged. `GameState` gained `owned_pets`/
`equipped_pet`, `pet_unlocked(pet_id)`/`pet_changed` signals, `equip_pet(id)` (`""` unequips,
requires ownership, clamps `player_hp` to the new effective max, and deliberately never
auto-heals on equip/unequip — only the first-grant path heals), `get_equipped_pet_bonus()`,
and `get_effective_max_hp()` (`PLAYER_MAX_HP` + the equipped pet's bonus), which
`take_player_damage()`/`heal_player_to_full()`/the HUD's hp readout now use instead of the old
fixed max. `Player.gd` spawns/despawns the pet as a sibling node on `pet_changed`, and on
`_ready()` if a loaded save already has a pet equipped. The character panel gained a Pets
section listing every owned pet ("Label (Rarity) +N Max HP", tinted by rarity color) with an
Equip/Unequip button each, and the equipped pet is now included in the equipment summary
line. Save schema bumped to version 3 (`owned_pets`/`equipped_pet`, same `Array[String]` JSON
coercion pattern already used for `owned_gear`); `_migrate()` stays a no-op since
`load_game()` already reads every field via `.get()` with defaults. Explicitly deferred (see
`docs/design/PETS.md`): pet combat, multiple species/a real roster, buying pets, evolution/
leveling, and real (non-placeholder) art. Test suite grew to 28 (a new, isolated
`tests/pet_tests.gd` with 5 tests: grant-gate ordering, grant-heal + idempotence, ownership/
clamp/no-auto-heal on equip, save/load round trip, and reset).
**Gentle repeatable coin faucet (expansion backlog): done.** `docs/design/GEAR_AND_ECONOMY.md`
had flagged the real pacing bottleneck: the M1 zone's 3 Meadow Slimes did not respawn, so a
fresh session yielded only ~3 coins from combat. `scripts/enemies/Spawner.gd`, attached to the
existing `Enemies` node in `Main.tscn`, fixes this without touching `MeadowSlime.gd`: it
records each slime's original spawn position on `_ready()`, and when one dies it schedules a
fresh instance at that position after a slow, tunable `respawn_delay_sec` (default 25s) —
always capped at the original count of 3 so the zone never feels crowded. The cap/cadence
decisions live in pure static functions (`Spawner.should_schedule_respawn()`,
`Spawner.count_due()`), following the same deterministic-testability precedent as
`MeadowSlime.rolls_bonus_coin()`. `docs/design/GEAR_AND_ECONOMY.md`'s faucet note is updated
from "flagged" to "addressed". A new isolated `tests/spawner_tests.gd` suite (7 tests) covers
the cap and due-time math.

**"Creatures met" codex (expansion backlog): done.** A tight, text-only collection loop per
`docs/design/NORTH_STAR.md` pillar 5 ("every short session yields permanent progress... a
codex entry"): `GameState.creatures_met` (a `Dictionary` mapping creature id -> `true`,
mirroring `collected_items`' shape) records the first time the player defeats each monster
type via `record_creature_met(id)` — idempotent, emitting a new `creature_met(creature_id)`
signal only on the first meeting — and `has_met_creature(id)`. `MeadowSlime._on_died()` gained
one line recording `"meadow_slime"`. `ContentDefinitions.CREATURE_FACTS` is a small plain
dictionary (id -> `{"label", "fact"}`, one entry so far), deliberately not a `.tres`
`Resource` since it doesn't meet the repo's "more content, or a second consumer" bar for
promotion. The character panel gained a "Creatures met" section (`CreaturesList`
`VBoxContainer`, refreshed via `_refresh_creatures_list()`) listing each met creature as
"Label — fact", with a "none yet" empty state matching the panel's other sections. Persisted
in save/load (save schema stays at version 3 — the new `creatures_met` key loads via `.get()`
with an in-code default, the same no-op migration policy every prior schema-compatible
addition has used) and cleared in `reset_state()`. Bonus-only by construction: entries are
never lost or gated behind a correct answer. Test suite grew to 32 (a new, isolated
`tests/codex_tests.gd` with 4 tests: first-meet records + signal fires once, repeat meet stays
idempotent, save/load round trip, reset clears).

**First mini-boss: Elder Slime (expansion backlog): done.** A deliberately tougher *variant*
of Meadow Slime rather than a new monster archetype, per NORTH_STAR's "cohesion over volume"
pillar: `scripts/enemies/ElderSlime.gd` is a small subclass of `MeadowSlime.gd`, reusing its
whole FSM/component architecture (`HealthComponent`, `HitboxComponent`/`HurtboxComponent`)
rather than a parallel monster script. It's tuned meaningfully tougher (6 hp vs. 3, slower
`move_speed` 30 vs. 40 so its one new move telegraphs clearly, `coin_drop_value` 3 vs. 1,
`bonus_coin_chance` 0.35 vs. 0.12) and adds exactly one new telegraphed move: a brief
pause-and-flash windup (`ElderSlime.telegraph_windup_intensity()`, a pure/unit-tested easing
mirroring `HealthComponent.hit_reaction_intensity()`'s precedent) followed by a fast lunge at
the player's position — a fair, clearly-visible tell before the bigger threat, honoring the
telegraphing research in `docs/design/RESEARCH_NOTES.md` §6.3. No new UI (boss health bar
etc.) — the existing HP/combat feedback is sufficient for this first pass, deliberately.
`scenes/enemies/ElderSlime.tscn` is placeholder art: the same `meadow_slime_idle.png` texture,
scaled 1.9x, tinted a regal gold (a later "boss visual polish" pass replaced the original
moss-green tint), with a small gold `Crown` `Polygon2D` above it, so it reads as visually
distinct and unmistakably a boss without requiring new production art before the system is
proven (see `docs/design/MONSTER_CONCEPTS.md`). Placed once, at `(2350, 1450)` — a far corner
of the M1 zone away from
the player spawn and existing quest/NPC content — under a new `Bosses` sibling `Node2D` in
`Main.tscn`, deliberately separate from the `Enemies` node `Spawner.gd` watches: an
endlessly-respawning mini-boss would cheapen the "first tougher fight" moment, so this is a
one-per-session encounter by design (not forced by the code — a future slice could add
deliberate re-fights). Records `elder_slime` in the "Creatures met" codex on death
(`ContentDefinitions.CREATURE_FACTS` gained a second entry). Test suite grew to 36 (a new,
isolated `tests/elder_slime_tests.gd` with 4 tests: telegraph-intensity ramp + zero-duration
edge case, stat-override comparison against the base Meadow Slime defaults, codex fact
lookup).

**Boss keepsake: Elder Slime drops a permanent trophy (expansion backlog): done.** Completes
the mini-boss's payoff loop with a text-only, non-stat trophy rather than a power boost, per
NORTH_STAR pillar 5. `GameState.keepsakes` (a `Dictionary` mapping keepsake id -> `true`)
mirrors the `creatures_met` codex shape exactly: `award_keepsake(id)` is idempotent, firing a
new `keepsake_awarded(keepsake_id)` signal only on the first award, and `has_keepsake(id)`
reads it back. `ElderSlime._on_died()` now calls `award_keepsake("elder_slime_dewdrop")`
alongside its existing `record_creature_met("elder_slime")` call, so a defeated boss cannot
re-drop the keepsake and a regular (non-boss) Meadow Slime never grants it.
`ContentDefinitions.KEEPSAKE_FACTS` is a small plain dictionary (id -> `{"label", "fact"}`,
one entry so far), the same promotion-bar reasoning as `CREATURE_FACTS`. The character panel
gained a "Keepsakes" section (`KeepsakesList` `VBoxContainer`, refreshed via
`_refresh_keepsakes_list()`) listing each earned keepsake as "Label — fact", with a "none yet"
empty state matching the panel's other sections. Persisted in save/load (no save-schema bump —
`keepsakes` loads via `.get()` with an in-code default, the same no-op migration policy every
prior schema-compatible addition has used) and cleared in `reset_state()`. A new, isolated
`tests/keepsake_tests.gd` (4 tests: first-award fires once, repeat award stays idempotent,
save/load round trip, reset clears) is registered in `tests/test_runner.gd`.
**Epic map pass (owner mandate — "make the maps interesting, beautiful, and epic"): done.**
A direct product-owner directive, not a backlog slice, honoring `docs/design/NORTH_STAR.md`'s
kid-audience framing (Grade 2/5: bright, readable, colorful, never busy or dark). The M1
bootstrap zone (160x100 tiles, 2560x1600px) is repainted and extended to **220x140 tiles
(3520x2240px, ~1.9x the old area)**, grown only to the right and down from the same origin so
every existing NPC/item/enemy/Player position stays exactly where it was, on the same terrain
it always stood on. The 4-tile placeholder tileset (`assets/sprites/tiles/
placeholder_tileset.png` / `assets/tilesets/placeholder_tileset.tres`) grows to 12 tiles,
generated by a new `assets/sprites/tiles/gen_tileset.py` (pure Pillow, kept beside the asset
for provenance, mirroring `assets/audio/gen_sfx.py`'s precedent): the original 4 tiles (grass/
path/water/rock) keep their exact atlas coordinates and colors so every already-painted cell
keeps its old meaning; 8 new tiles are appended (two grass-shade variants, two flower-meadow
tiles, a darker forest-floor grass, sand/shore, a deep-water variant, and a stone/cliff border
tile). Water, deep-water, rock, and cliff all carry the same full-tile physics collision
polygon as the original water/rock. **Regions:** a warm-grass, flower-dotted village green
around the Elder/Merchant/Finn cluster; an open flower meadow south of it (existing path
network + Yarrow/Silverleaf); a darker forest-floor band along the west edge near Mira/
LoneTree with tree-cluster props; the old water rectangle reshaped into a natural-edged lake
(sand shore ring, small deep-water core) at its original spot; and a 2-tile-thick rock/cliff
border framing the whole new map edge (the old border ring, now interior, is repainted as
normal terrain). The original path network (spawn/village row/Mira spur/lake spur) is re-laid
on top of every region so it stays exactly as walkable and readable as before, now extended
into the bigger space. New depth props: 5 more `LoneTree` instances (forest-edge clusters), 2
more `StandingStone` instances (border), and two new placeholder-polygon props,
`scenes/props/Bush.tscn` and `scenes/props/Dock.tscn` (a small lakeside dock), all purely
visual (no collision, `y_sort_enabled` like their siblings). The Player's `Camera2D` limits
move to the new bounds (`limit_right`/`limit_bottom` 3520/2240). The whole repaint is
one-shot, deterministic, documented-as-code: `tools/paint_map.gd` (run via the tiny
`tools/PaintMapRunner.tscn`, since `godot --script` skips the project's normal autoload
bootstrap that `Main.tscn`'s node scripts and `[connection ...]` entries depend on — see that
script's header comment) loads `Main.tscn`, disables processing before it enters the tree (so
no wander/physics AI nudges a position while the tool has the scene open), calls `set_cell()`
per region, adds the new prop instances, and saves via `PackedScene.pack()` +
`ResourceSaver.save()`. A new isolated `tests/map_tests.gd` (5 tests, registered in
`tests/test_runner.gd`) instances `Main.tscn` and asserts: the `Ground` `TileMapLayer` exists
and its used-cell count grew past the old zone's 16,000; every NPC/item (Elder, Mira, Finn,
Yarrow, Merchant, Collectible, GlowingHerb, ShimmeringOre, Silverleaf) and every Meadow Slime
sits at its exact hardcoded original position; the landmark props are still at their original
spots; and the camera limits match the new bounds.

**Stealthier numeracy: Yarrow's coin check as an in-fiction action (expansion backlog):
done.** A format-only reframe of Yarrow's existing Grade 2 numeracy check, per
`docs/design/RESEARCH_NOTES.md` §8.2's intrinsic-integration principle ("the work is the
game" — express the skill as an in-fiction action, not an abstract quiz prompt).
`scripts/npcs/Yarrow.gd`'s Grade 2 prompt changed from "Which coin is worth more?" to "The
remedy jar costs a dime. Which coin do you hand me?" — the same two coin choices, the same
correct answer (`a dime`), the same already-confirmed G2 money/number-sense competency, wired
through the same `LearningCheck` scene and `GameState.award_quest_bonus()` bonus-only path.
No new subject, no new mechanic, no new test surface (the mechanic itself is unchanged, so
the existing `LearningCheck`/`GameState` quest tests already cover it). Grade 5's word-choice
check is untouched. `ContentDefinitions.QUEST_SUMMARIES`'s Yarrow `learning_check` line
updated to "Pay Yarrow for the remedy jar" to match. See `docs/design/CURRICULUM_MAP.md` for
the updated check text and the note that this does not touch the CONFIRM-gated subject table.

**Diegetic session-end "rest" beat: a cozy campfire (expansion backlog): done.** Per
`docs/design/NORTH_STAR.md` pillar 5 and the project's anti-dark-pattern posture
(`RESEARCH_NOTES.md` §8.1): a single interactable `Campfire` (`scenes/props/Campfire.tscn` /
`scripts/props/Campfire.gd`) sits in the village green at `(1288, 588)` — north of the
Merchant, inside the warm-grass village cluster (Elder/Merchant/Finn row, player spawn just
south), clear of every existing NPC/prop/path. It mirrors an NPC's interact pattern exactly
(`InteractionArea` + "Press E" prompt, same shape as `Yarrow.gd`) but carries no quest state:
interacting always calls `GameState.save_game()`, emits `dialogue_requested` with a
profile-aware rest line (`Campfire.get_rest_message(profile)`, a pure static function — Grade
2 gets a short plain line, Grade 5 a slightly richer one), and emits a new `rested` signal.
Placeholder polygon art (log-brown base + orange/yellow flame triangles) has a cheap looping
Tween-driven flame flicker (scale pulses on `Flame`/`FlameInner`), the same low-cost "juice"
approach as `HealthComponent`'s hit-flash. `rested` is wired straight to a new
`RestFadeOverlay` (`scenes/ui/RestFadeOverlay.tscn` / `scripts/ui/RestFadeOverlay.gd`, a
`CanvasLayer` + full-screen `ColorRect`, layer 95) whose `play_rest_fade()` tweens the overlay
to a warm dim (0.55 alpha) and back over ~2s — a calm visual beat, not a game-over/quit; input
and gameplay are never blocked, and the child can keep playing immediately after. Strictly
bonus-only per the acceptance criteria: no streak, no timer, no "come back tomorrow" messaging,
and nothing is ever lost by not resting — it's purely a positive closure beat layered on top
of the save system that already existed. No save-schema change (`save_game()` is called as-is)
and no `project.godot` edits. A new isolated `tests/campfire_tests.gd` (3 tests: Grade 2's
short message, Grade 5's message differs and is longer, unknown-profile fallback) is
registered in `tests/test_runner.gd`.

**Region ambience pass (expansion backlog): done.** Generalizes the M-audio-pass's single
global ambient loop into region-aware playback matching the "Epic map pass" regions, per
`docs/design/NORTH_STAR.md`'s cohesion-over-volume pillar and `RESEARCH_NOTES.md` §8.3/§8.4.
`AudioManager.gd` now owns two ping-ponged `AudioStreamPlayer`s instead of one; a cheap ~0.5s
`Timer` poll (`_on_region_poll_timeout()`) reads the player's `global_position` (via
`get_tree().get_first_node_in_group("player")`, the same lookup precedent `MeadowSlime.gd`/
`ElderSlime.gd` already use) and looks it up against `REGION_RECTS` — one rectangle per region
in world-pixel space, hand-derived from `tools/paint_map.gd`'s tile regions (16px tiles) so
both files describe the same geography: lake, forest edge, village green, flower meadow, and a
map-spanning rocky-border fallback, checked in that order (first match wins) so lake/forest/
village/meadow take priority over the outer border rect they sit inside. On a region change,
`_crossfade_to_region()` starts the new region's track on the idle player at silence and ramps
both players' `volume_db` over `CROSSFADE_DURATION_SEC` (1.75s) via a pure, unit-tested easing
function - no hard cut, no silence gap. Four new self-synthesized ambient WAVs extend
`assets/audio/gen_sfx.py` (same provenance precedent as the original sound pass): `village_
hearth` (a very soft warm low-tone bed), `meadow_birds` (the meadow pad bed plus a few
deterministic soft chirps), `forest_wind` (filtered-noise swells via a slowly-modulated
low-pass cutoff), and `lake_water` (a soft periodic lapping envelope over dark noise) - all
peak-normalized well under full scale and loop-seam-faded like the existing `ambient_meadow`
track. The old `ambient_meadow.wav` track is kept and reused as the rocky-border region's
ambient (rather than deleted), since it already reads as a neutral open-field bed. Two pure,
unit-tested static functions back this: `AudioManager.region_for_position(pos, region_rects,
default_region)` (rectangle lookup) and `AudioManager.crossfade_volume_db(t, target_db,
is_incoming)` (linear-in-dB fade easing, clamped, with -80 dB standing in for silent) — both
mirroring `coins_increased()`'s pure-static-function precedent. No gameplay change: pure
atmosphere. Test suite grew to 61 (6 new `AudioTests` cases: in-rect lookups for all 4 named
regions, first-match-wins on overlap, outside-all-rects fallback, inclusive/exclusive rect
boundary edges, and the cross-fade easing's endpoints/midpoint/clamping).

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `AGENTS.md`: project and agent workflow guidance, including the current `ContentDefinitions.gd` rule for lightweight quest/item/profile display text.
- `assets/sprites/tiles/placeholder_tileset.png`, `assets/sprites/tiles/gen_tileset.py`, and `assets/tilesets/placeholder_tileset.tres`: the placeholder tileset, now 12 16x16 tiles (grown from the original bootstrap 4: grass/path/water/rock, plus 2 grass-shade variants, 2 flower-meadow tiles, forest-floor grass, sand, deep water, and a stone/cliff border tile), generated as flat colors by `gen_tileset.py` (pure Pillow, not the AI source-art pipeline — see the "Epic map pass" writeup above). The original 4 tiles keep their exact atlas coordinates/colors. Water, deep-water, rock, and cliff all carry a full-tile physics collision polygon on `TileSet` physics layer 0; every grass/path/flower/sand variant is walkable.
- `scenes/main/Main.tscn`: `World/Ground` `TileMapLayer` (220x140 tiles, 3520x2240px as of the "Epic map pass", `y_sort_enabled` on `World`) replacing the old flat floor/obstacle, player, Elder, Mira, Finn, Yarrow (all `y_sort_enabled`), collectibles (including Silverleaf), HUD, dialogue, character panel, profile selector, learning check, `Enemies` (3 `MeadowSlime` instances), and `CombatQuestion` instances.
- `tools/paint_map.gd` / `tools/PaintMapRunner.tscn`: the one-shot, deterministic, documented-as-code map repaint tool behind the "Epic map pass" (see writeup above) — not part of any shipped scene, kept for future map iteration.
- `scenes/props/Bush.tscn` and `scenes/props/Dock.tscn`: two more placeholder-polygon depth props (Epic map pass), matching `StandingStone.tscn`/`LoneTree.tscn`'s convention (no collision, no script, `y_sort_enabled`).
- `tests/map_tests.gd`: a fifth isolated test suite (5 tests) for the Epic map pass — see writeup above — registered in `tests/test_runner.gd`.
- `scripts/core/combat/HealthComponent.gd`, `HitboxComponent.gd`, `HurtboxComponent.gd`: the M2 component architecture. `HealthComponent` tracks hp with a brief post-hit immunity window (`hit_cooldown_sec`) and a `died` signal; `HitboxComponent` is a toggleable damage zone with a `landed` signal so an attacker can react to connecting; `HurtboxComponent` detects overlapping hitboxes by group membership ("hitbox"/"hurtbox" - not a dedicated physics layer, since everything in this project already defaults to layer/mask 1) and auto-discovers a sibling node named "HealthComponent" in `_ready()` rather than relying on a typed node export (a raw `NodePath(...)` literal written into `.tscn` text does not reliably resolve to a `HealthComponent` reference — a real bug caught live, see below). A `HurtboxComponent` never damages its own owner (same-parent check), since an enemy's own contact-damage hitbox and hurtbox occupy the same space. `HealthComponent` also drives a brief **hit-flash** on damage (RESEARCH_NOTES §7.1): it auto-discovers a sibling `Body` sprite and briefly pops its scale (+ tints toward white) so a landed hit reads instantly — a gentle, no-screen-shake "juice" pass added by the expansion loop. The timing easing (`HealthComponent.hit_reaction_intensity()`) is pure and unit-tested in `tests/hit_flash_tests.gd` (a second suite registered in `tests/test_runner.gd`); `Player.gd` reuses the same easing for a soft-red player-hurt flash.
- `scripts/enemies/MeadowSlime.gd` / `scenes/enemies/MeadowSlime.tscn`: the first monster. Simple idle/wander/chase FSM (aggro radius, home-anchored wander), a `HealthComponent` (3 hp), a `Hurtbox` (receives player hits), and an always-on `ContactHitbox` (deals contact damage to the player). Real art (`assets/sprites/enemies/meadow_slime_idle.png`, via `assets/manifests/meadow_slime_idle.manifest.json`); see `docs/design/MONSTER_CONCEPTS.md`. On death it always spawns its guaranteed 1-coin `CoinPickup`, plus rolls an exported `bonus_coin_chance` (default 12%) for one additional bonus coin via the pure, deterministically-testable `MeadowSlime.rolls_bonus_coin(chance, roll)` — see `docs/design/GEAR_AND_ECONOMY.md`'s "Bonus drop rule".
- `scripts/enemies/Spawner.gd`: attached to the `Enemies` node in `Main.tscn` (gentle repeatable coin faucet). Records each Meadow Slime's original spawn position on `_ready()`, and when one dies (`tree_exited`), schedules a fresh instance at the same position after a slow, tunable `respawn_delay_sec` (default 25s) — always capped at the original count of 3 so the zone never crowds. The cap/cadence decisions are pure static functions (`should_schedule_respawn`, `count_due`), deterministically unit-tested in `tests/spawner_tests.gd` without a scene tree, mirroring `MeadowSlime.rolls_bonus_coin()`'s precedent. See `docs/design/GEAR_AND_ECONOMY.md`'s faucet note, now addressed.
- `scenes/ui/CombatQuestion.tscn` / `scripts/ui/CombatQuestion.gd`: the combat damage-multiplier question. Deliberately separate from `LearningCheck` (no quest coupling, dismisses itself immediately on answer). A small numeracy-only question pool per profile, matching the already-confirmed subject scope in `docs/design/CURRICULUM_MAP.md`.
- `scenes/player/Player.tscn`: player `Body` (`AnimatedSprite2D`, `sprite_frames` built in code per profile — see `Player.gd`), a hidden empty `Armor` (`AnimatedSprite2D`) scaffold for a future equipment layer, collision shape, camera (`Camera2D` now has `limit_left/top/right/bottom` set to the map bounds and `position_smoothing_enabled` on), an `AttackHitbox` (toggled on for a brief window each swing, repositioned per facing direction), and a `PlayerHurtbox` (always-on, receives enemy hits).
- `scripts/player/Player.gd` (combat additions): a new `attack` input action (Space or left click, added via the Godot Input Map) swings `AttackHitbox` in the player's current facing direction (`FACING_VECTORS`), gated by an active window + cooldown so it can't be spammed. Landing a hit (the `HitboxComponent.landed` signal) requests a combat question if one isn't on cooldown; taking a hit (`PlayerHurtbox.hit_received`) calls `GameState.take_player_damage()`. On `GameState.player_died`, the player teleports back to wherever it started the scene (captured once in `_ready()` as `_spawn_position`), heals to full, and shows a brief non-punitive dialogue line — no game over screen.
- `scripts/core/GameState.gd`: minimal profile, health, collected-item, reusable quest state (now four quests: Elder, Mira, Finn, Yarrow), and Elder compatibility flags. Also owns the equip system: `equipped_armor_tier` (0 = none) and an `armor_equipped(tier)` signal, granted automatically by `_check_and_grant_tier1_armor()` once all four quests reach `QUEST_COMPLETED` (called from `complete_quest()`). And local save/load: `save_game()`/`load_game()`/`reset_progress()` persist the fields above to `user://savegame.json`; `load_game()` runs in `_ready()`. Autosave is wired via four small `_on_<signal>_autosave()` handlers, one per signal (`profile_changed`, `quest_changed`, `item_added`, `armor_equipped`), each just calling `save_game()` — **not** one shared zero-arg handler connected to all four (see the note below on why that doesn't work). Now also owns real player combat: `take_player_damage()`/`heal_player_to_full()` (with their own hit-cooldown, same pattern as `HealthComponent`) and the combat streak/multiplier (`combat_streak`, `get_combat_multiplier()`, `answer_combat_question()`, decaying over time in `_process()`) — deliberately **not** persisted, since it's a moment-to-moment combat feel mechanic, not saved progress.
- `scripts/core/ContentDefinitions.gd`: tiny lookup layer for profile labels, item labels, quest summaries, badge labels, and armor tier labels (`get_badge_label(quest_id)`/`BADGE_LABELS`, `get_armor_tier_label(tier)`/`ARMOR_TIER_LABELS` — both deliberately plain dictionaries, not `.tres` resources, since neither meets the "more content, or a second consumer needing structured data" bar `AGENTS.md` sets for promoting to Resources). Item labels are resolved from `ItemDefinition` `.tres` resources (see below); profile labels, quest summaries, badge labels, and armor tier labels are still plain dictionaries.
- `scripts/core/ItemDefinition.gd` and `data/items/{golden_star,glowing_herb,shimmering_ore,silverleaf}.tres`: a tiny Resource-backed content experiment (`docs/ROADMAP.md` milestone 2) — each item's id/label now lives in its own `.tres` file instead of a hardcoded dictionary entry, proving the pattern works before it's considered for quest/profile content too.
- `scripts/player/Player.gd`: WASD and arrow-key movement blocked until profile selection; swaps the player sprite by profile via `GameState.profile_changed`, and by movement direction (8-way, with west/south-west/north-west mirrored from east/south-east/north-east via `flip_h`) as the player moves. Builds one `SpriteFrames` per profile in `_ready()` (cached in `_profile_frames`) containing both an `idle_<direction>` animation (1 frame) and a `walk_<direction>` animation (4-frame loop: idle, walk1, idle, walk2) per direction, and plays the matching one on the `AnimatedSprite2D` `body` node based on whether the player is currently moving. Also builds a second per-profile cache (`_profile_armor_frames`) from the Tier 1 armor textures, reusing the same builder with no walk poses (so armored walking falls back to a static armored idle pose); `_update_sprite()` picks that cache whenever `GameState.equipped_armor_tier > 0`, refreshed on `GameState.armor_equipped`.
- `scenes/npcs/Elder.tscn` and `scripts/npcs/Elder.gd`: purple Elder placeholder with golden-star quest.
- `scenes/npcs/Mira.tscn` and `scripts/npcs/Mira.gd`: green gardener NPC with glowing-herb quest.
- `scenes/npcs/Finn.tscn` and `scripts/npcs/Finn.gd`: brown blacksmith placeholder with shimmering-ore quest gated after Mira completion.
- `scenes/npcs/Yarrow.tscn` and `scripts/npcs/Yarrow.gd`: pale-robed village healer with a silverleaf quest gated after Finn completion — the fourth quest, added on top of the tested `GameState` base; mirrors Finn.gd's shape exactly.
- `scenes/items/Collectible.tscn` and `scripts/items/Collectible.gd`: reusable pickup logic.
- `scenes/items/GlowingHerb.tscn`: glowing-herb pickup for Mira's quest.
- `scenes/items/ShimmeringOre.tscn`: shimmering-ore pickup for Finn's quest.
- `scenes/items/Silverleaf.tscn`: silverleaf pickup for Yarrow's quest.
- `scripts/ui/HUD.gd`: visible objective text that updates based on selected profile and active quest state; chains through all four quests in order (Elder → Mira → Finn → Yarrow), falling through to the next once the current one completes. Now also shows an "HP: 5/5" readout, a gold "Coins: N" readout (reading `GameState.coins_changed`, added by the expansion loop so the player always sees their spendable coins while fighting/earning, not only in the shop/panel), and an "On Fire! x1.5"-style combat streak label (hidden at streak 0), reading `GameState.player_damaged`/`combat_streak_changed`.
- `scenes/ui/DialogueBox.tscn` and `scripts/ui/DialogueBox.gd`: reusable speaker/message UI dismissed with E, Enter, or Space.
- `scenes/ui/ProfileSelect.tscn` and `scripts/ui/ProfileSelect.gd`: profile selector overlay UI and logic.
- `scenes/ui/LearningCheck.tscn` and `scripts/ui/LearningCheck.gd`: reusable profile-aware two-choice learning check.
- `scenes/ui/CharacterPanel.tscn` and `scripts/ui/CharacterPanel.gd`: placeholder character/inventory popup opened with C or I and backed by content definitions. `Items:` now lists every collected item generically (any id in `GameState.collected_items`, with an "x2" suffix for counts above 1) instead of three hardcoded checks. `Bonuses earned:` now lists earned badge names (e.g. "Elder's Wisdom Badge") instead of a bare count, checking all four quests. `Current quest:` chains through all four quests, same as HUD. Also has a "Reset Progress..." button (mouse-only, no keyboard shortcut) that reveals a two-step confirm sub-view ("Cancel" vs "Yes, erase everything") before calling `GameState.reset_progress()` — deliberately hard to trigger by accident for the Grade 2/5 target audience.
- `scripts/ui/LearningCheck.gd`: a correct answer's completion dialogue now names the earned badge (e.g. "Bonus earned! You've received the Elder's Wisdom Badge.") instead of a generic "Bonus earned!" line.
- `assets/README.md` and `assets/sprites/README.md`: asset folder structure guidance.
- `assets/source/.gdignore` and `assets/source/README.md`: ignored source/reference material area.
- `docs/art/ASSET_PIPELINE.md` and `docs/art/STYLE_GUIDE.md`: first art workflow and visual rules.
- `tools/asset_pipeline/` (`manifest.py`, `normalize.py`, `validate.py`, `test_pipeline.py`): Python + Pillow tool that turns AI-generated source art into exact, correctly-sized, transparent PNGs via a JSON manifest. See `docs/art/ASSET_NORMALIZATION_PIPELINE.md`.
- `assets/manifests/.gdignore` and `assets/source/generated/.gdignore`: Godot-ignored folders for normalization manifests and raw AI source sheets.
- `project.godot` sets the project-wide default texture filter to nearest, as `docs/design/VISUAL_CONTRACT.md` requires — set during the pipeline proof pass (PR #16), which normalized one ChatGPT test render end to end before any production art existed. That proof-pass sprite (`hero_body_idle_s.*`) was later deleted once superseded by real production art and confirmed unreferenced by any scene/script (see `docs/ROADMAP.md`'s cleanup backlog).
- `assets/manifests/adventurer_body_idle_{s,se,e,ne,n}.manifest.json`, matching `assets/source/generated/adventurer_body_idle_*/source.png`, and `assets/sprites/characters/adventurer_body_idle_*.png`: the first production art for Grade 5 Adventurer — a user-approved "practical traveler" design, 5 directions covering all 8 facings via future `flip_h` mirroring of the SE/E/NE renders. Only `_s` (south) is currently used in `Player.tscn`.
- `assets/manifests/mage_body_idle_{s,se,e,ne,n}.manifest.json`, `assets/source/generated/mage_body_idle_sheet/source.png` (a single shared 5-panel source sheet, generated in one ChatGPT response and addressed per direction via `sourceCell` on a 5-col grid), and `assets/sprites/characters/mage_body_idle_*.png`: production art for Grade 2 Mage, matching the brown-haired, navy/gold-tunic design from the V2 style reference. Only `_s` (south) is currently wired into `Player.gd`.
- `assets/manifests/{mage,adventurer}_body_walk{1,2}_{s,se,e,ne,n}.manifest.json` (20 manifests), `assets/source/generated/{mage,adventurer}_body_walk_sheet/source.png` (one shared 5-direction x 2-pose grid sheet per character, generated in one ChatGPT response each, addressed via `sourceCell` on a 5-col x 2-row grid), and `assets/sprites/characters/{mage,adventurer}_body_walk{1,2}_*.png`: the two new mid-stride poses per direction per character that drive the walk-cycle animation (see `Player.gd` above). `walk1`/`walk2` combine with the existing `idle` pose at runtime — no third pose was generated for "neutral", since idle already serves that role.
- `assets/manifests/{mage,adventurer}_body_idle_tier1_{s,se,e,ne,n}.manifest.json` (10 manifests), `assets/source/generated/{mage,adventurer}_body_idle_tier1_sheet/source.png` (one shared 5-direction grid sheet per character, a ChatGPT in-place edit of the base idle sheet adding leather armor), and `assets/sprites/characters/{mage,adventurer}_body_idle_tier1_*.png`: Tier 1 (Leather) armor art, see `docs/design/ARMOR_TIERS.md`. Normalized as full replacement body sprite sets (not a transparent overlay — see that doc for why the original diff-based overlay plan was dropped). Now wired into `Player.gd`/`GameState.gd`: completing all three quests auto-equips it (see above); no manual equip/unequip UI exists.
- `tests/TestRunner.tscn`, `tests/test_runner.gd`, `tests/game_state_tests.gd`: a small custom headless GDScript test suite for `GameState` (no third-party test framework/addon), 18 tests (16 through M3, plus the Legendary Dawnbringer Blade buy/equip/+4 test, plus `MeadowSlime.rolls_bonus_coin()`'s boundary/hit/miss cases — preloaded directly from `scripts/enemies/MeadowSlime.gd` since it's a pure static function). Eight more isolated suites are registered alongside it in `test_runner.gd`: `tests/hit_flash_tests.gd` (5), `tests/pet_tests.gd` (5: grant-gate ordering, grant-heal + idempotence, ownership/clamp/no-auto-heal on equip, save/load round trip, reset), `tests/spawner_tests.gd` (7: coin-faucet respawn cap/cadence pure logic), `tests/audio_tests.gd` (3: `AudioManager.coins_increased()`, unknown-name no-op), `tests/codex_tests.gd` (4: first-meet records + signal fires once, repeat meet stays idempotent, save/load round trip, reset clears), `tests/elder_slime_tests.gd` (4: telegraph-intensity ramp + zero-duration edge case, stat-override comparison, codex fact lookup), `tests/keepsake_tests.gd` (4: first-award fires once, repeat award stays idempotent, save/load round trip, reset clears), and `tests/map_tests.gd` (5: the Epic map pass geometry/position assertions). Suite total is **55 tests**. See "How to run the GDScript test suite" below.
- `scripts/core/GearDefinition.gd` and `data/gear/{worn_dagger,iron_sword,oakheart_blade,dawnbringer_blade}.tres`: the gear-stats Resource, mirroring `ItemDefinition.gd` — id/label/rarity/damage_bonus/price per weapon (`dawnbringer_blade` is the Legendary top tier added by the expansion loop).
- `scripts/items/CoinPickup.gd` / `scenes/items/CoinPickup.tscn`: coin pickup, mirroring `Collectible.gd`; spawned (deferred) by `MeadowSlime._on_died()`.
- `scripts/npcs/Merchant.gd` / `scenes/npcs/Merchant.tscn`: the gear vendor NPC. Interacting opens `ShopUI` directly (no dialogue box needed).
- `scripts/ui/ShopUI.gd` / `scenes/ui/ShopUI.tscn`: the shop panel, built from `ContentDefinitions.GEAR_DEFINITIONS` at runtime (no per-item scene nodes to maintain). Buy buttons disable once owned or unaffordable.
- `docs/design/GEAR_AND_ECONOMY.md`: locks the M3 rarity list and weapon roster (id/rarity/damage/price) for future gear additions.
- `scenes/props/StandingStone.tscn` and `scenes/props/LoneTree.tscn`: two placeholder-polygon wayfinding landmark props (no collision, no script), instanced once each in `Main.tscn` beside the north village fork and the west garden fork so the two main paths are distinguishable from a distance. Added by the expansion loop (map-readability slice).
- `scripts/core/PetDefinition.gd` and `data/pets/mossy.tres`: the pet-stats Resource, mirroring `GearDefinition.gd` — id/label/rarity/hp_bonus. `mossy` is the first and only pet (Rare, +2 Max HP). See `docs/design/PETS.md`.
- `scripts/pets/Pet.gd` / `scenes/pets/Pet.tscn`: follow-only pet AI (`CharacterBody2D`, no `HealthComponent`, no combat) — moves toward the player at speed 220 whenever farther than 24px away, stops inside that ring (player speed is 160). Placeholder polygon art (mint/teal blob with a leaf and eyes).
- `scripts/core/GameState.gd` (pet additions): `owned_pets`/`equipped_pet`, `pet_unlocked(pet_id)`/`pet_changed` signals, `equip_pet(id)` (`""` unequips, requires ownership, clamps `player_hp` to the new effective max, never auto-heals on equip/unequip), `get_equipped_pet_bonus()`, `get_effective_max_hp()` (now used by `take_player_damage()`/`heal_player_to_full()`/the HUD hp readout), and `_check_and_grant_first_pet()` (same all-four-quests gate as the Tier 1 armor grant, called from `complete_quest()`; grants and auto-equips Mossy once, healing by the bonus so the new max arrives full). Save schema bumped to version 3 (`owned_pets`/`equipped_pet`).
- `scripts/player/Player.gd` (pet addition): spawns/despawns the equipped pet as a sibling node on `GameState.pet_changed`, and on `_ready()` if a loaded save already has a pet equipped.
- `scripts/ui/CharacterPanel.gd` (pet addition): a new Pets section lists every owned pet ("Label (Rarity) +N Max HP", tinted by rarity color) with an Equip/Unequip button each; the equipped pet is included in the equipment summary line.
- `docs/design/PETS.md`: locks the M4 pet unlock/equip rules, Mossy's stats, and the follow-AI parameters for future pet additions.
- **Audio (sound pass v1, expansion backlog): done.** The game previously had zero audio. A
  new `AudioManager` autoload (`scripts/core/AudioManager.gd`, registered in `project.godot`
  after `GameState`) owns every `AudioStreamPlayer` in the game, created in code in its own
  `_ready()` — no scene-file edits to `Main.tscn` needed. One looping ambient meadow track
  plays quietly in the background (-18 dB, replayed on `finished` rather than relying on
  import-time loop flags), plus a small pool of one-shot SFX players (-10 dB) for `swing`,
  `slime_boing`, `coin_chime`, `quest_fanfare`, and `ui_click`, looked up by name via
  `play_sfx(name)` (an unknown name is a silent no-op with `push_warning`, never a crash).
  `AudioManager` connects directly to `GameState.coins_changed` (plays `coin_chime` only when
  coins actually increased, via the pure/unit-tested `AudioManager.coins_increased()` helper)
  and `GameState.quest_changed` (plays `quest_fanfare` on `QUEST_COMPLETED`). One-line hooks
  call `AudioManager.play_sfx(...)` from `Player._swing_attack()` (swing),
  `MeadowSlime._on_died()` (slime_boing), `ShopUI._on_buy_pressed()` (ui_click), and a new
  `CharacterPanel._on_equip_weapon_pressed()` wrapper around the existing
  `GameState.equip_weapon` call (ui_click). All 6 WAVs are self-synthesized (no third-party
  license concerns) under `assets/audio/` — `assets/audio/gen_sfx.py` is the generator script,
  kept for provenance/reproducibility. Volumes are deliberately soft per
  `docs/design/NORTH_STAR.md`'s kid-audience (Grade 2/5) gentle-feedback rule. A new isolated
  `tests/audio_tests.gd` (registered in `tests/test_runner.gd`) adds 3 tests for the pure
  `coins_increased()` helper and the unknown-name no-op.
- `scripts/core/GameState.gd` ("Creatures met" codex additions): `creatures_met: Dictionary`, `record_creature_met(id)` (idempotent, fires `creature_met(creature_id)` once per new id), `has_met_creature(id)`, persisted via `save_game()`/`load_game()`/cleared in `reset_state()`.
- `scripts/core/ContentDefinitions.gd` (codex addition): `CREATURE_FACTS` (plain dictionary, id -> `{label, fact}`) + `get_creature_label(id)`/`get_creature_fact(id)`.
- `scripts/ui/CharacterPanel.gd`/`.tscn` (codex addition): a "Creatures met" section (`CreaturesList` `VBoxContainer`) listing each met creature as "Label — fact", refreshed on `GameState.creature_met`.
- `tests/codex_tests.gd`: a fourth isolated test suite (4 tests) for the "Creatures met" codex, registered in `tests/test_runner.gd`.
- `scripts/enemies/ElderSlime.gd` / `scenes/enemies/ElderSlime.tscn` (first mini-boss): a small subclass of `MeadowSlime.gd` reusing its FSM/components, tuned tougher (6 hp, slower `move_speed`, bigger coin drop/bonus chance) and adding one telegraphed pause-flash-then-lunge move (`telegraph_windup_intensity()`, pure/unit-tested). Placeholder art: the Meadow Slime texture scaled 1.5x and tinted deep moss green. Placed once at `(2350, 1450)` under a new `Bosses` sibling node in `Main.tscn` (not under `Enemies`/`Spawner.gd`, so it does not respawn). Records `elder_slime` in the codex on death.
- `scripts/core/ContentDefinitions.gd` (Elder Slime addition): a second `CREATURE_FACTS` entry, `elder_slime`.
- `tests/elder_slime_tests.gd`: a fifth isolated test suite (4 tests) for the Elder Slime mini-boss, registered in `tests/test_runner.gd`.
- `scripts/core/GameState.gd` (boss keepsake addition): `keepsakes: Dictionary`, `award_keepsake(id)` (idempotent, fires `keepsake_awarded(keepsake_id)` once per new id), `has_keepsake(id)`, persisted via `save_game()`/`load_game()`/cleared in `reset_state()`.
- `scripts/core/ContentDefinitions.gd` (boss keepsake addition): `KEEPSAKE_FACTS` (plain dictionary, id -> `{label, fact}`) + `get_keepsake_label(id)`/`get_keepsake_fact(id)`.
- `scripts/enemies/ElderSlime.gd` (boss keepsake addition): `_on_died()` now also calls `GameState.award_keepsake("elder_slime_dewdrop")`.
- `scripts/ui/CharacterPanel.gd`/`.tscn` (boss keepsake addition): a "Keepsakes" section (`KeepsakesList` `VBoxContainer`) listing each earned keepsake as "Label — fact", refreshed on `GameState.keepsake_awarded`.
- `tests/keepsake_tests.gd`: a sixth isolated test suite (4 tests) for boss keepsakes, registered in `tests/test_runner.gd`.
- `scenes/props/Campfire.tscn` / `scripts/props/Campfire.gd`: the diegetic session-end rest beat. A placeholder-polygon campfire (log-brown base + orange/yellow flame triangles, gentle Tween-driven flicker) in the village green at `(1288, 588)`. Interacting mirrors an NPC's interact pattern (no quest state): calls `GameState.save_game()`, emits `dialogue_requested` with a profile-aware rest line (`Campfire.get_rest_message(profile)`, pure/unit-tested), and emits `rested`.
- `scenes/ui/RestFadeOverlay.tscn` / `scripts/ui/RestFadeOverlay.gd`: a `CanvasLayer` + full-screen `ColorRect` (layer 95) whose `play_rest_fade()` tweens to a warm dim and back over ~2s, wired to `Campfire.rested` in `Main.tscn`. Purely a calm visual beat — never blocks input or gameplay.
- `tests/campfire_tests.gd`: a seventh isolated test suite (3 tests: Grade 2's short message, Grade 5's differs/longer, unknown-profile fallback) for the campfire rest beat, registered in `tests/test_runner.gd`.
- `scripts/core/AudioManager.gd` (region ambience pass): generalized from one global ambient loop to region-aware playback — `REGION_RECTS` (world-pixel rectangles matching `tools/paint_map.gd`'s tile regions), `REGION_STREAMS` (one loop per region), a ~0.5s `Timer` poll of the player's position, and a two-player cross-fade (`_crossfade_to_region()`) driven by the pure `region_for_position()`/`crossfade_volume_db()` static functions.
- `assets/audio/gen_sfx.py` (region ambience pass additions): `village_hearth()`, `meadow_birds()`, `forest_wind()`, `lake_water()` — four new self-synthesized, soft, loop-seam-faded ambient beds, one per region (see writeup above).
- `assets/audio/{village_hearth,meadow_birds,forest_wind,lake_water}.wav`: the generated region ambient tracks.
- `tests/audio_tests.gd` (region ambience pass additions): 6 new tests for `region_for_position()` (in-rect lookups, first-match-wins on overlap, outside-all-rects fallback, inclusive/exclusive boundary edges) and `crossfade_volume_db()` (endpoints, midpoint, clamping). Suite total is now 64 (55 + 3 campfire + 6 region ambience).

## How to run

Open `project.godot` with Godot 4.x standard and press F5.

## How to run the GDScript test suite

```
Godot_v4.7-stable_win64_console.exe --headless --path . res://tests/TestRunner.tscn
```

Runs all 10 isolated suites registered in `tests/test_runner.gd` - `tests/game_state_tests.gd`
(18), `tests/hit_flash_tests.gd` (5), `tests/pet_tests.gd` (5), `tests/spawner_tests.gd` (7),
`tests/audio_tests.gd` (9), `tests/codex_tests.gd` (4), `tests/elder_slime_tests.gd` (4),
`tests/keepsake_tests.gd` (4), `tests/map_tests.gd` (5), and `tests/campfire_tests.gd` (3) -
against the real `GameState`/`AudioManager` autoloads, and prints `PASS`/`FAIL` per test plus
a summary line (**64 tests total**); exits non-zero if anything failed. See
`tests/test_runner.gd` for the
(small, custom, no third-party dependency) runner — it discovers every `test_*` method on
each registered test class, resets `GameState` via `GameState.reset_state()` before each one
for isolation, and reports results.

**This writes to the real `user://savegame.json`** (deleted by the final test, but present
mid-run) — `--user-data-dir <path>` normally isolates this, but combining it with a custom
scene argument hung indefinitely on this Windows/Godot 4.7 build for reasons not yet
diagnosed; skip it for now and expect the suite to touch your local save file transiently.

## Manual test checklist

### Baseline regression

- [ ] Project opens without parser errors.
- [ ] F5 runs `Main.tscn`.
- [ ] Profile selector appears at launch, blocking movement and interaction.
- [ ] Grade 2 selection works (Button or Key 2).
- [ ] Grade 5 selection works (Button or Key 5).
- [ ] `selected_profile` is recorded in GameState.
- [ ] HUD text changes by profile.
- [ ] Elder offer dialogue changes by profile.
- [ ] Movement works after profile selection.
- [ ] Green floor, player sprite, brown obstacle, Elder, Mira, Finn, golden star, glowing herb, and shimmering ore are visible.
- [ ] The player sprite renders crisp (nearest-neighbor, no blur) with a transparent background and feet roughly aligned with the collision shape, not floating or sunk into the ground.
- [ ] Grade 2 selection shows the brown-haired Mage sprite; Grade 5 selection shows the distinct golden-haired Adventurer sprite.
- [ ] Moving in each of the 8 directions (WASD/arrows, including diagonals) turns the player sprite to face that direction; west-side facings are mirrored, not distinct art.
- [ ] Player sprite still renders identically to before (no visible regression) now that `Body` is an `AnimatedSprite2D` instead of a `Sprite2D`.
- [ ] Holding a movement key plays a walking animation (legs alternate) instead of a static pose; releasing the key returns immediately to the idle pose, for both profiles and in all 8 directions.
- [ ] The player cannot pass through the obstacle.
- [ ] Elder golden-star quest completes after the learning check regardless of answer; a correct answer's dialogue includes "Bonus earned!".
- [ ] After Elder quest completes, HUD points to Mira.
- [ ] Mira offers the glowing-herb quest.
- [ ] Touching the glowing herb removes it and records `glowing_herb` in GameState.
- [ ] Returning to Mira opens the profile-aware learning check.
- [ ] Wrong answer still completes the Mira quest, with no bonus.
- [ ] Correct answer completes the Mira quest and the dialogue line includes "Bonus earned!".
- [ ] Existing documentation remains present.

### Content definitions regression

- [ ] Character panel still shows `Grade 2 Mage` for the Grade 2 profile.
- [ ] Character panel still shows `Grade 5 Adventurer` for the Grade 5 profile.
- [ ] Character panel still shows current quest summary during Elder quest states.
- [ ] Character panel still shows current quest summary during Mira quest states.
- [ ] Character panel shows current quest summary during Finn quest states after Mira is completed.
- [ ] Character panel still shows `Golden Star` after collection.
- [ ] Character panel still shows `Glowing Herb` after collection.
- [ ] Character panel shows `Shimmering Ore` after collection.

### Character panel regression

- [ ] Pressing C or I after profile selection opens/closes the character panel.
- [ ] Character panel shows selected profile.
- [ ] Character panel shows current quest summary.
- [ ] Character panel shows collected items after the golden star, glowing herb, and shimmering ore are collected.
- [ ] Character panel shows "Equipment: none yet" before armor is earned.
- [ ] Character panel shows "Bonuses earned: none yet" before any bonus is earned, and lists the earned badge name(s) (e.g. "Elder's Wisdom Badge") as correct learning-check answers are given.
- [ ] A correct learning-check answer's completion dialogue names the earned badge (e.g. "...You've received the Elder's Wisdom Badge.").
- [ ] Character panel's Items line lists every collected item by name (not just the original three), with an "x2" suffix if the same item is collected more than once.
- [ ] Existing Elder, Mira, Finn, and Yarrow quest flows still work while the character panel is opened and closed.

### Finn quest regression

- [ ] Finn appears as a brown blacksmith placeholder.
- [ ] Interacting with Finn before Mira is complete tells the player to help Mira first.
- [ ] After Mira is complete, HUD points to Finn.
- [ ] Finn offers the shimmering-ore quest.
- [ ] Touching shimmering ore removes it and records `shimmering_ore` in GameState.
- [ ] Returning to Finn opens the profile-aware learning check.
- [ ] Grade 2 Finn question accepts `fish` as the correct answer.
- [ ] Grade 5 Finn question accepts `2/4` as the correct answer.
- [ ] Wrong answer still completes the Finn quest, with no bonus.
- [ ] Correct answer completes the Finn quest and the dialogue line includes "Bonus earned!".

### Yarrow quest regression

- [ ] Yarrow appears as a pale-robed healer near the south of the map.
- [ ] Interacting with Yarrow before Finn is complete tells the player to help Finn first.
- [ ] After Finn is complete, HUD points to Yarrow.
- [ ] Yarrow offers the silverleaf quest.
- [ ] Touching silverleaf removes it and records `silverleaf` in GameState.
- [ ] Returning to Yarrow opens the profile-aware learning check.
- [ ] Grade 2 Yarrow question accepts `a dime` as the correct answer.
- [ ] Grade 5 Yarrow question accepts `kind` as the correct answer.
- [ ] Wrong answer still completes the Yarrow quest, with no bonus.
- [ ] Correct answer completes the Yarrow quest and the dialogue line includes "Bonus earned!".
- [ ] After Yarrow's quest completes, HUD and character panel show a completion message
      rather than pointing to a fifth quest that doesn't exist.

### Equip system regression

- [ ] Before completing all four quests, character panel shows "Equipment: none yet".
- [ ] The instant the fourth quest (Elder, Mira, Finn, or Yarrow, in any order) completes,
      the player sprite immediately shows Tier 1 (Leather) armor for both Grade 2 Mage and
      Grade 5 Adventurer, without needing to reopen the character panel or restart.
- [ ] Character panel shows "Equipment: Leather Armor" after all four quests complete.
- [ ] Walking in any direction while armored shows a static armored pose (no leg animation)
      instead of the unarmored walk-cycle.
- [ ] Switching profiles (if applicable) shows the correct character's own armored sprite,
      not the other character's.

### Save/load and reset regression

- [ ] Fresh launch with no prior save shows the profile selector as before.
- [ ] Selecting a profile, collecting an item, or completing a quest each cause the game to
      autosave (no visible UI for this — it's silent/automatic).
- [ ] Quitting and relaunching the game auto-resumes exactly where you left off: the profile
      selector does NOT appear, the player sprite/facing/armor is correct, previously
      collected world pickups do not reappear, and the character panel shows the same quest
      progress, items, bonuses, and equipment as before quitting.
- [ ] Character panel's "Reset Progress..." button is mouse-only — it has no keyboard
      shortcut and doesn't trigger from WASD/E/C/I mashing.
- [ ] Clicking "Reset Progress..." shows a confirm sub-view ("Erase ALL progress? This
      cannot be undone.") instead of resetting immediately.
- [ ] Clicking "Cancel" hides the confirm sub-view and changes nothing.
- [ ] Clicking "Yes, erase everything" clears all progress, reloads the scene, and shows the
      profile selector again as if freshly launched with no save.

### World/map regression

- [ ] The zone is visibly bigger than one screen — walking in any direction moves well past
      the original single-screen bounds before hitting the outer rock border.
- [ ] Grass and dirt-path tiles are walkable; the player cannot walk into water or rock
      tiles, or past the outer rock border at the edge of the map.
- [ ] The camera stops scrolling at the map edges (no empty/gray space beyond the tiled
      zone) and follows the player smoothly rather than snapping instantly.
- [ ] The player and all 4 NPCs draw in correct front/behind order as the player walks
      above/below them (y-sort).
- [ ] All 4 NPC quests (Elder, Mira, Finn, Yarrow) are still reachable and completable in
      their new positions, in the same gated order as before (Elder → Mira → Finn → Yarrow).
- [ ] Two wayfinding landmark props are visible from the spawn area (a screen or so away):
      a tall grey **Standing Stone** with a gold cap to the north (marking the Elder / Merchant
      / Finn village cluster) and a green **Lone Tree** to the west (marking Mira's garden
      path). A first-time player can tell, from the landmarks alone, that the northern fork
      leads to the quest-givers/shop and the western fork leads toward the garden. The props
      are purely visual (no collision — the player passes them as background scenery) and no
      existing NPC/collectible/path moved.
- [ ] (Epic map pass) The map reads as distinct regions, not a flat rectangle: a warm
      flower-dotted village green around the Elder/Merchant/Finn cluster, an open flower
      meadow south of it, a darker forest-floor band with tree clusters along the west edge
      near Mira, a lake with a sand shore (not a hard-edged rectangle) at its original spot,
      and a rocky/cliff border framing the whole map edge.
- [ ] (Epic map pass) The playable zone is noticeably bigger again (220x140 tiles vs the
      original 160x100) with the camera stopping at the new, farther-out edges.
- [ ] (Epic map pass) A few extra trees are visible clustered near the forest edge, a stone
      or two near the far border, a couple of bushes scattered near the village/lake area, and
      a small wooden dock at the lake's shore — all purely visual, no collision.

### Combat regression

- [ ] Pressing Space or left-clicking swings a brief visible slash near the player in the
      direction they're facing.
- [ ] The player can move freely while a Meadow Slime is nearby and while fighting it —
      combat never locks movement or forces a battle-transition screen.
- [ ] A Meadow Slime wanders near its spawn point when the player is far away, and chases
      the player once they get close.
- [ ] Landing 3 hits on a Meadow Slime (with brief pauses between swings so the slime's own
      hit-immunity window doesn't eat a swing) defeats it; it shrinks and disappears.
- [ ] Touching a Meadow Slime deals contact damage to the player (visible as the HP counter
      dropping), but standing in continued contact doesn't drain HP every frame.
- [ ] The first hit landed on a slime after a pause pops a quick 2-choice math question;
      answering (click, or press 1/2) closes it immediately and combat keeps going.
- [ ] A correct answer shows "On Fire! x1.5" (then x2, x2.5) in the HUD; it fades back down
      over time if no further correct answers land. A wrong answer never reduces it.
- [ ] Letting player HP reach 0 (e.g. standing in repeated slime contact) doesn't show a
      game-over screen — the player reappears at the zone's original spawn point with full
      HP and a brief friendly message.
- [ ] All 4 NPC quests still complete normally with Meadow Slimes present in the zone.
- [ ] Hitting a Meadow Slime makes it briefly "pop" (a quick scale bump) so a landed hit
      reads instantly; the pop settles back within a fraction of a second and never sticks.
- [ ] Taking contact damage makes the player briefly flash soft-red and pop, then settle
      back — a gentle "ouch", no screen shake.

### Gear & shop regression

- [ ] Defeating a Meadow Slime drops a small coin pickup; walking over it increases the
      coin count.
- [ ] Defeating several Meadow Slimes occasionally drops a second coin pickup alongside the
      guaranteed one (roughly 1 in 8, tunable) — never fewer than the guaranteed 1 coin.
- [ ] Approaching the Merchant NPC and pressing E opens the shop panel, listing all three
      weapons with their rarity color, damage bonus, and price.
- [ ] Buying a weapon deducts the exact price from coins and its button switches to
      "Owned"; buying again is not possible.
- [ ] Attempting to buy a weapon costing more than the current coin balance is blocked (its
      Buy button stays disabled).
- [ ] Opening the character panel shows the current coin count and lists every owned
      weapon with an Equip button; equipping one updates the `Equipment:` line and the
      button switches to "Equipped".
- [ ] Equipping a weapon visibly increases attack damage (a Meadow Slime dies in fewer
      hits than with no weapon equipped).
- [ ] Coins, owned gear, and the equipped weapon all survive a save/reload (relaunching the
      game resumes with the same values).
- [ ] All 4 NPC quests and Meadow Slime combat still work normally with the Merchant and
      shop present in the zone.

### Pet system regression

- [ ] The instant the fourth quest (Elder, Mira, Finn, or Yarrow, in any order) completes,
      a Mossy pet appears beside the player and follows automatically — no manual pickup or
      equip step needed.
- [ ] The player's max HP increases by 2 the moment Mossy is granted, and the player is
      healed to the new max (not left at the old max looking "damaged").
- [ ] The pet keeps its distance while the player stands still and moves to catch up once
      the player walks away, without overtaking or blocking the player.
- [ ] Opening the character panel shows Mossy in a Pets section ("Mossy (Rare) +2 Max HP")
      and the `Equipment:` line includes it.
- [ ] Clicking Unequip in the character panel removes the pet from the world immediately and
      returns max HP to the base value (current HP is clamped down if needed, but the player
      is never auto-healed by equipping or unequipping).
- [ ] Clicking Equip again respawns the pet beside the player without re-healing or
      re-granting it.
- [ ] The equipped pet and max-HP bonus survive a save/reload (relaunching the game resumes
      with the pet still following).
- [ ] All 4 NPC quests, combat, and the shop still work normally with Mossy present.

### Audio regression

- [ ] A quiet ambient meadow track loops in the background from the moment the game starts,
      and never abruptly cuts out or clips when it loops.
- [ ] Swinging (Space or left click) plays a soft swish sound.
- [ ] Defeating a Meadow Slime or Elder Slime plays a "boing"-style sound.
- [ ] Picking up a coin plays a chime, and it does not play on any other pickup.
- [ ] Completing a quest plays a fanfare sound.
- [ ] Clicking Buy in the shop or Equip in the character panel plays a soft UI click.
- [ ] All sounds are gentle/soft in volume, never sudden or harsh, appropriate for a Grade 2/5
      audience.

### Creatures codex & mini-boss regression

- [ ] Defeating a Meadow Slime for the first time records it in the character panel's
      "Creatures met" section ("Meadow Slime — <fact>"); defeating more does not duplicate it.
- [ ] The Elder Slime (a larger, gold-tinted slime wearing a small crown, in the far corner of
      the map) is visibly tougher than a regular Meadow Slime and telegraphs a pause-and-flash
      windup before lunging at the player, giving a fair, readable warning before the hit.
- [ ] Defeating the Elder Slime records `Elder Slime` in the "Creatures met" section and awards
      a keepsake shown in a new "Keepsakes" section of the character panel (e.g. "Elder Slime's
      Dewdrop — <fact>"); re-encountering it (if it ever respawned) would not re-award the
      keepsake.
- [ ] Neither the codex entries nor the keepsake are ever lost or gated behind a correct
      learning-check answer — bonus-only, non-punitive.

## Next milestone

A design north-star doc set lives in `docs/design/` (`NORTH_STAR.md`, `CURRICULUM_MAP.md`, `VISUAL_CONTRACT.md`, `RESEARCH_NOTES.md`) to anchor future work. The learning checks now follow its bonus-only rule: each quest completes on item return regardless of answer, and a correct answer adds a bonus via `GameState.award_quest_bonus()`.

The asset normalization pipeline (`tools/asset_pipeline/`, see `docs/art/ASSET_NORMALIZATION_PIPELINE.md`) can now turn approved ChatGPT/Gemini source art into Godot-ready sprites, and the architecture rule's "do not scale asset replacement until one pass is proven" gate is satisfied: one hero sprite has gone source image -> manifest -> normalize -> validate -> `Player.tscn`, importing and running cleanly under Godot 4.7 headless. That sprite is a test/comparison render, not approved production art — still needed before a real asset pass: production hero/armor source art (using the Eldoria-V2 committed sprites and `docs/art/ASSET_NORMALIZATION_PIPELINE.md` prompting tips as style/process reference), the Godot-side paper-doll `AnimatedSprite2D` layering for armor, and 8-direction `flip_h` mirroring.

Both Grade 5 Adventurer and Grade 2 Mage now have production art with real 8-direction
movement-facing wired into `Player.gd` (see above). Remaining visual gaps: no walk-cycle
animation (still a single idle pose per direction) and no armor/paper-doll layering yet.

Earned learning-check bonuses are now visible to the player via the character panel's
"Bonuses earned: X/3" line (see above), closing the gap left by the earlier bonus-only
learning-check rework.

The tiny Resource experiment (`docs/ROADMAP.md` milestone 2) is done: item display labels
now come from `ItemDefinition` `.tres` resources under `data/items/`. Quest summaries and
profile labels are deliberately left as dictionaries — no concrete need to migrate those yet.

The inventory/reward foundation (`docs/ROADMAP.md` milestone 4) is done: the character
panel's item list is now generic (any collected item, not a hardcoded three), and learning
check bonuses are named badges the player can see, both in the completion dialogue and in
the character panel, instead of an anonymous flag/count.

The `AnimatedSprite2D` engine foundation for walk-cycle animation and armor/paper-doll
layering is done (see above), and walk-cycle animation itself is now live for both
characters (see above) — both Grade 2 Mage and Grade 5 Adventurer walk with a 4-frame loop
in all 8 directions.

An armor tier progression has been designed (`docs/design/ARMOR_TIERS.md` — leather, bronze,
iron, gold, diamond, ninja, dragon, cosmic, dark, applied identically across both
characters with character-appropriate silhouettes). Tier 1 (Leather) art has been generated
and normalized for both characters as full replacement body sprite sets (see above and
`docs/design/ARMOR_TIERS.md` for why the diff-based transparent-overlay plan was dropped in
favor of reusing the existing body-art pipeline unmodified).

The equip system (`docs/ROADMAP.md` milestone 5) is done: completing all three quests
auto-equips Tier 1 armor via `GameState.equipped_armor_tier` / `armor_equipped` signal, the
player sprite updates immediately, and the character panel shows what's equipped (see above
and `docs/design/ARMOR_TIERS.md`). The `Armor` `AnimatedSprite2D` node remains
hidden/empty — this milestone used the full-body-swap approach on `Body` instead, not that
scaffold; it may still suit small separable accessories (capes, masks) later. There is no
manual equip/unequip UI, and armored walking is a static pose (no tier1 walk-cycle art
exists yet) — both are accepted limitations of this deliberately minimal slice, not bugs.

Local save/load (`docs/ROADMAP.md` milestone 6) is done: `GameState` autosaves to
`user://savegame.json` on every profile/quest/item/armor change and auto-resumes silently
on relaunch, with no "Continue vs New Game" menu (see above). A "Reset Progress..." control
was added in the same milestone (not deferred), with a two-step confirm deliberately hard
for a Grade 2/5 player to trigger by accident. A real bug was caught and fixed during live
verification: connecting one shared zero-argument autosave handler to all four of
`GameState`'s own signals silently failed to dispatch for any signal that emits arguments —
only a same-object connection with mismatched arity was affected; identical connections
from other scripts (`Player.gd`, `HUD.gd`, `CharacterPanel.gd`) to those same signals fired
correctly throughout, and connecting to a genuinely zero-arg signal also worked. The fix
was four small per-signal handlers matching each signal's exact arity, mirroring the
matching-arity pattern every other signal listener in this codebase already used. Diagnosed
live via the `godot-ai` MCP bridge's `editor_manage(op="game_eval")`, which executes
arbitrary GDScript in the running game and was the tool that made this diagnosis possible.

A small custom GDScript test suite now exists (`tests/`, no third-party framework) covering
`GameState`'s quest lifecycle, item/quest wiring, badge tracking, the Tier 1 armor grant,
and the save/load/reset round trip — see "How to run the GDScript test suite" above.
Building it caught two more real bugs, both fixed: `collected_items` counts silently
becoming floats after a JSON save/load round trip (JSON numbers always parse as float;
`Dictionary` values have no static type to auto-coerce them back, unlike
`equipped_armor_tier`'s declared `int` type), and a signal connected to a **lambda** (as
opposed to a named method) on a `RefCounted` object not reliably firing on this Godot 4.7
build even when the identical signal correctly reached a named-method listener — every
probe in the test suite now uses a named method for this reason. `GameState.reset_progress()`
was also split into `reset_state()` (data clearing) + a conditional scene reload, so the
state-clearing half can be tested headlessly without a loaded scene to reload.

A fourth quest is done: **Yarrow the Healer** (`QUEST_YARROW_SILVERLEAF`), gated behind
Finn, mirroring the existing Elder/Mira/Finn shape exactly. Deliberately scoped narrow per
`docs/design/NORTH_STAR.md`'s "resist feature equity across many NPCs/biomes" guidance and
`docs/design/CURRICULUM_MAP.md`'s unconfirmed subject-scope flag — same village hub, same
linear gate chain, same already-confirmed numeracy/literacy subjects, not a new archetype.
The Tier 1 armor grant now requires all four quests (backward-compatible: armor never
un-grants once earned). This is a judgment call made autonomously while the user was away;
flagged clearly here for review — a different next quest, a different subject, or declining
to extend the armor requirement would all have been reasonable alternate choices.

The user has since approved a **Phase 2 roadmap** (`docs/ROADMAP.md`'s "Phase 2" section) —
the placeholder vertical slice is done, and the project is moving toward a real game
(combat, pets, bigger maps, farm, mobile). **M1 (world/map foundation) is done**:
`TileMapLayer` + collision + camera limits + y-sort, proven with a bootstrap placeholder
tileset. **M2 (combat + first monster) is done** (see above): the `HealthComponent`/
`HitboxComponent`/`HurtboxComponent` architecture, a real-time hack-and-slash player attack,
the Meadow Slime as the first monster, and the user's math-question damage-multiplier/streak
idea. No stats `.tres` was introduced in M2 — its numbers (hp, damage, speed) stayed plain
`@export` vars on `HealthComponent`/`MeadowSlime.gd`, since a single monster and the
player's fixed stats didn't yet meet the "more content, or a second consumer needing
structured data" bar. **M3 (gear, rarity, coins & shop) is done** (see above): the first real
stats `.tres`, `GearDefinition`, landed as flagged, backing a tight three-weapon vertical
slice (one gear slot, one vendor, manual equip) rather than the full gear/inventory surface —
see `docs/design/GEAR_AND_ECONOMY.md`.

**M4 (pets) is done** (see above): `PetDefinition`, the first and only pet Mossy (Rare, +2 Max
HP), follow-only AI with no combat, the same all-four-quests auto-grant gate as Tier 1 armor,
and a Pets section in the character panel — see `docs/design/PETS.md`. Real tile art to
replace the placeholder tileset, Tier 1 walk-cycle armor art, Tier 2 (Bronze) armor, real
coin/gear icon art, and real pet art (currently placeholder polygons) all remain open art
backlog items, lower priority than the Phase 2 milestone chain.

Since M4, the autonomous expansion loop (`docs/design/EXPANSION_BACKLOG.md`) has shipped a
run of small, additive slices on top of the gear/economy/pets base (see each one's writeup
above, in order): the Meadow Slime bonus-chance coin drop, the gentle repeatable coin faucet
(`Spawner.gd`), a sound pass v1 (`AudioManager` autoload, ambient + SFX), the "Creatures met"
codex, the first mini-boss (Elder Slime) plus its boss keepsake payoff, the epic region-distinct
map pass (220x140 tiles: village green / flower meadow / forest edge / lake+dock / rocky
border), and the stealthier in-fiction reframe of Yarrow's numeracy check. Test suite grew to
**55 tests across 9 isolated suites** (see "How to run the GDScript test suite" below). This
run of slices also stands in for a meaningful chunk of the Phase 2 plan's **M5 — bigger world
& traversal** milestone (the map is now ~1.9x its original area with distinct readable
regions), though M5 was never formally kicked off as its own milestone — it happened
organically through the expansion backlog instead.

The current frontier (in progress, not yet merged) is three more `ready` expansion-backlog
slices sequenced after the map pass — discovery sparkle-spots (hidden exploration finds across
the new regions), a diegetic campfire "rest" beat (a cozy, non-punitive session-end stopping
point), and a region ambience pass (per-region ambient sound cross-fading as the player
crosses the map) — alongside a fresh art/learning research pass per the owner's "cool
backgrounds, epic art, learning out the wazoo" mandate. See
`docs/agent-workflow/CONDUCTOR_DIRECTIVE.md` for the current build-order snapshot and
`docs/design/EXPANSION_BACKLOG.md` for each slice's full acceptance criteria.
