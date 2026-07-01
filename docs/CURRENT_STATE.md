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
(mirroring `ItemDefinition.gd`) backs three weapons under `data/gear/` (Worn Dagger/Common/
+1, Iron Sword/Uncommon/+2, Oakheart Blade/Rare/+3). Meadow Slimes now drop exactly 1 coin on
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

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `AGENTS.md`: project and agent workflow guidance, including the current `ContentDefinitions.gd` rule for lightweight quest/item/profile display text.
- `assets/sprites/tiles/placeholder_tileset.png` and `assets/tilesets/placeholder_tileset.tres`: bootstrap 4-tile (grass/path/water/rock) 16x16 placeholder tileset, generated as flat colors (not through the AI source-art pipeline, since it exists only to prove `TileMapLayer`/`TileSet` collision before real tile art). Water and rock tiles have a full-tile physics collision polygon on `TileSet` physics layer 0; grass and path have none (walkable).
- `scenes/main/Main.tscn`: `World/Ground` `TileMapLayer` (160x100 tiles, 2560x1600px, `y_sort_enabled` on `World`) replacing the old flat floor/obstacle, player, Elder, Mira, Finn, Yarrow (all `y_sort_enabled`), collectibles (including Silverleaf), HUD, dialogue, character panel, profile selector, learning check, `Enemies` (3 `MeadowSlime` instances), and `CombatQuestion` instances.
- `scripts/core/combat/HealthComponent.gd`, `HitboxComponent.gd`, `HurtboxComponent.gd`: the M2 component architecture. `HealthComponent` tracks hp with a brief post-hit immunity window (`hit_cooldown_sec`) and a `died` signal; `HitboxComponent` is a toggleable damage zone with a `landed` signal so an attacker can react to connecting; `HurtboxComponent` detects overlapping hitboxes by group membership ("hitbox"/"hurtbox" - not a dedicated physics layer, since everything in this project already defaults to layer/mask 1) and auto-discovers a sibling node named "HealthComponent" in `_ready()` rather than relying on a typed node export (a raw `NodePath(...)` literal written into `.tscn` text does not reliably resolve to a `HealthComponent` reference — a real bug caught live, see below). A `HurtboxComponent` never damages its own owner (same-parent check), since an enemy's own contact-damage hitbox and hurtbox occupy the same space.
- `scripts/enemies/MeadowSlime.gd` / `scenes/enemies/MeadowSlime.tscn`: the first monster. Simple idle/wander/chase FSM (aggro radius, home-anchored wander), a `HealthComponent` (3 hp), a `Hurtbox` (receives player hits), and an always-on `ContactHitbox` (deals contact damage to the player). Real art (`assets/sprites/enemies/meadow_slime_idle.png`, via `assets/manifests/meadow_slime_idle.manifest.json`); see `docs/design/MONSTER_CONCEPTS.md`. On death it always spawns its guaranteed 1-coin `CoinPickup`, plus rolls an exported `bonus_coin_chance` (default 12%) for one additional bonus coin via the pure, deterministically-testable `MeadowSlime.rolls_bonus_coin(chance, roll)` — see `docs/design/GEAR_AND_ECONOMY.md`'s "Bonus drop rule".
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
- `scripts/ui/HUD.gd`: visible objective text that updates based on selected profile and active quest state; chains through all four quests in order (Elder → Mira → Finn → Yarrow), falling through to the next once the current one completes. Now also shows an "HP: 5/5" readout and an "On Fire! x1.5"-style combat streak label (hidden at streak 0), reading `GameState.player_damaged`/`combat_streak_changed`.
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
- `tests/TestRunner.tscn`, `tests/test_runner.gd`, `tests/game_state_tests.gd`: a small custom headless GDScript test suite for `GameState` (no third-party test framework/addon), 17 tests as of the Meadow Slime bonus-coin slice (16 from M3, plus 1 new: `MeadowSlime.rolls_bonus_coin()`'s boundary/hit/miss cases, preloaded directly from `scripts/enemies/MeadowSlime.gd` since it's a pure static function). See "How to run the GDScript test suite" below.
- `scripts/core/GearDefinition.gd` and `data/gear/{worn_dagger,iron_sword,oakheart_blade}.tres`: the M3 gear-stats Resource, mirroring `ItemDefinition.gd` — id/label/rarity/damage_bonus/price per weapon.
- `scripts/items/CoinPickup.gd` / `scenes/items/CoinPickup.tscn`: coin pickup, mirroring `Collectible.gd`; spawned (deferred) by `MeadowSlime._on_died()`.
- `scripts/npcs/Merchant.gd` / `scenes/npcs/Merchant.tscn`: the gear vendor NPC. Interacting opens `ShopUI` directly (no dialogue box needed).
- `scripts/ui/ShopUI.gd` / `scenes/ui/ShopUI.tscn`: the shop panel, built from `ContentDefinitions.GEAR_DEFINITIONS` at runtime (no per-item scene nodes to maintain). Buy buttons disable once owned or unaffordable.
- `docs/design/GEAR_AND_ECONOMY.md`: locks the M3 rarity list and weapon roster (id/rarity/damage/price) for future gear additions.

## How to run

Open `project.godot` with Godot 4.x standard and press F5.

## How to run the GDScript test suite

```
Godot_v4.7-stable_win64_console.exe --headless --path . res://tests/TestRunner.tscn
```

Runs `tests/game_state_tests.gd` against the real `GameState` autoload and prints
`PASS`/`FAIL` per test plus a summary line; exits non-zero if anything failed. See
`tests/test_runner.gd` for the (small, custom, no third-party dependency) runner — it
discovers every `test_*` method on `GameStateTests`, resets `GameState` via
`GameState.reset_state()` before each one for isolation, and reports results.

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

Next up: **M4 — pets**, per the Phase 2 plan. Real tile art to replace the placeholder
tileset, Tier 1 walk-cycle armor art, Tier 2 (Bronze) armor, and real coin/gear icon art all
remain open art backlog items, lower priority than the Phase 2 milestone chain.

Separately, the autonomous expansion loop (`docs/design/EXPANSION_BACKLOG.md`) has started
shipping small post-M3 slices on top of the gear/economy loop: the Meadow Slime bonus-chance
coin drop (see above) is the first one, done.
