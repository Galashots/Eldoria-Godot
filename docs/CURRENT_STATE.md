# Current State

## Status

Milestones 1 through 14 are complete and merged: the PR branch-sync docs rule, the `docs/design/` north-star doc set, the bonus-only realignment of the Elder/Mira/Finn learning checks, the Python asset normalization pipeline (`tools/asset_pipeline/`), and a proof pass that normalizes one ChatGPT test render through the pipeline and displays it on the player in place of the flat-color placeholder.

The player sprite is now profile-aware and direction-aware: `Player.gd` swaps its texture based on `GameState.selected_profile` and the player's current movement direction. Both Grade 5 Adventurer and Grade 2 Mage have production 5-direction idle sets (south/south-east/east/north-east/north, generated from user-approved ChatGPT designs and normalized through the pipeline). The Mage set was generated as a single 5-panel sheet in one ChatGPT response (rather than 5 separate generations like the Adventurer) and cropped into a shared source image addressed by grid cell per direction — proving that approach also works. All 8 facings are now live: west/south-west/north-west mirror east/south-east/north-east via `flip_h`, matching the 5-render-plus-mirroring convention. The player's `Body` node is now an `AnimatedSprite2D` (was a plain `Sprite2D`), with one `SpriteFrames` resource per profile built in code from the existing idle textures (each direction is a single-frame animation, e.g. `idle_s`) — this is a zero-visual-change engine migration that gets the architecture ready for real multi-frame walk animations later, since adding walk frames will just mean calling `add_frame()` more times on the same `SpriteFrames`. A hidden, empty sibling `Armor` `AnimatedSprite2D` node also now exists, reserved for a future paper-doll equipment layer; no armor art exists yet, so `Armor` stays invisible. Walk-cycle animation is now live for both characters: each direction has a 4-frame loop (idle -> walk1 -> idle -> walk2, reusing the existing idle pose as the neutral "passing" frame rather than commissioning a full frame-by-frame cycle) that plays automatically while the player is moving, and reverts to the static idle pose the instant movement stops. Tier 1 (Leather) armor art now exists for both characters as full replacement idle sprite sets (see `docs/design/ARMOR_TIERS.md`), normalized through the same pipeline as base body art, but nothing in-game equips it yet.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `AGENTS.md`: project and agent workflow guidance, including the current `ContentDefinitions.gd` rule for lightweight quest/item/profile display text.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, player, Elder, Mira, Finn, collectibles, HUD, dialogue, character panel, profile selector, and learning check instances.
- `scenes/player/Player.tscn`: player `Body` (`AnimatedSprite2D`, `sprite_frames` built in code per profile — see `Player.gd`), a hidden empty `Armor` (`AnimatedSprite2D`) scaffold for a future equipment layer, collision shape, and camera.
- `scripts/core/GameState.gd`: minimal profile, health, collected-item, reusable quest state, and Elder compatibility flags.
- `scripts/core/ContentDefinitions.gd`: tiny lookup layer for profile labels, item labels, quest summaries, and badge labels (`get_badge_label(quest_id)`, a `BADGE_LABELS` dictionary keyed by quest id — deliberately not a `.tres` resource, since 3 fixed display strings don't meet the "more content, or a second consumer needing structured data" bar `AGENTS.md` sets for promoting to Resources). Item labels are resolved from `ItemDefinition` `.tres` resources (see below); profile labels, quest summaries, and badge labels are still plain dictionaries.
- `scripts/core/ItemDefinition.gd` and `data/items/{golden_star,glowing_herb,shimmering_ore}.tres`: a tiny Resource-backed content experiment (`docs/ROADMAP.md` milestone 2) — each item's id/label now lives in its own `.tres` file instead of a hardcoded dictionary entry, proving the pattern works before it's considered for quest/profile content too.
- `scripts/player/Player.gd`: WASD and arrow-key movement blocked until profile selection; swaps the player sprite by profile via `GameState.profile_changed`, and by movement direction (8-way, with west/south-west/north-west mirrored from east/south-east/north-east via `flip_h`) as the player moves. Builds one `SpriteFrames` per profile in `_ready()` (cached in `_profile_frames`) containing both an `idle_<direction>` animation (1 frame) and a `walk_<direction>` animation (4-frame loop: idle, walk1, idle, walk2) per direction, and plays the matching one on the `AnimatedSprite2D` `body` node based on whether the player is currently moving.
- `scenes/npcs/Elder.tscn` and `scripts/npcs/Elder.gd`: purple Elder placeholder with golden-star quest.
- `scenes/npcs/Mira.tscn` and `scripts/npcs/Mira.gd`: green gardener NPC with glowing-herb quest.
- `scenes/npcs/Finn.tscn` and `scripts/npcs/Finn.gd`: brown blacksmith placeholder with shimmering-ore quest gated after Mira completion.
- `scenes/items/Collectible.tscn` and `scripts/items/Collectible.gd`: reusable pickup logic.
- `scenes/items/GlowingHerb.tscn`: glowing-herb pickup for Mira's quest.
- `scenes/items/ShimmeringOre.tscn`: shimmering-ore pickup for Finn's quest.
- `scripts/ui/HUD.gd`: visible objective text that updates based on selected profile and active quest state.
- `scenes/ui/DialogueBox.tscn` and `scripts/ui/DialogueBox.gd`: reusable speaker/message UI dismissed with E, Enter, or Space.
- `scenes/ui/ProfileSelect.tscn` and `scripts/ui/ProfileSelect.gd`: profile selector overlay UI and logic.
- `scenes/ui/LearningCheck.tscn` and `scripts/ui/LearningCheck.gd`: reusable profile-aware two-choice learning check.
- `scenes/ui/CharacterPanel.tscn` and `scripts/ui/CharacterPanel.gd`: placeholder character/inventory popup opened with C or I and backed by content definitions. `Items:` now lists every collected item generically (any id in `GameState.collected_items`, with an "x2" suffix for counts above 1) instead of three hardcoded checks. `Bonuses earned:` now lists earned badge names (e.g. "Elder's Wisdom Badge") instead of a bare count.
- `scripts/ui/LearningCheck.gd`: a correct answer's completion dialogue now names the earned badge (e.g. "Bonus earned! You've received the Elder's Wisdom Badge.") instead of a generic "Bonus earned!" line.
- `assets/README.md` and `assets/sprites/README.md`: asset folder structure guidance.
- `assets/source/.gdignore` and `assets/source/README.md`: ignored source/reference material area.
- `docs/art/ASSET_PIPELINE.md` and `docs/art/STYLE_GUIDE.md`: first art workflow and visual rules.
- `tools/asset_pipeline/` (`manifest.py`, `normalize.py`, `validate.py`, `test_pipeline.py`): Python + Pillow tool that turns AI-generated source art into exact, correctly-sized, transparent PNGs via a JSON manifest. See `docs/art/ASSET_NORMALIZATION_PIPELINE.md`.
- `assets/manifests/.gdignore` and `assets/source/generated/.gdignore`: Godot-ignored folders for normalization manifests and raw AI source sheets.
- `assets/manifests/hero_body_idle_s.manifest.json`, `assets/source/generated/hero_body_idle_s/source.png`, `assets/sprites/characters/hero_body_idle_s.png`: the proof-pass hero sprite (one direction, no armor, from a ChatGPT test render — not approved production art) and its manifest, proving the pipeline end-to-end. `project.godot` now sets the project-wide default texture filter to nearest, as `docs/design/VISUAL_CONTRACT.md` requires.
- `assets/manifests/adventurer_body_idle_{s,se,e,ne,n}.manifest.json`, matching `assets/source/generated/adventurer_body_idle_*/source.png`, and `assets/sprites/characters/adventurer_body_idle_*.png`: the first production art for Grade 5 Adventurer — a user-approved "practical traveler" design, 5 directions covering all 8 facings via future `flip_h` mirroring of the SE/E/NE renders. Only `_s` (south) is currently used in `Player.tscn`.
- `assets/manifests/mage_body_idle_{s,se,e,ne,n}.manifest.json`, `assets/source/generated/mage_body_idle_sheet/source.png` (a single shared 5-panel source sheet, generated in one ChatGPT response and addressed per direction via `sourceCell` on a 5-col grid), and `assets/sprites/characters/mage_body_idle_*.png`: production art for Grade 2 Mage, matching the brown-haired, navy/gold-tunic design from the V2 style reference. Only `_s` (south) is currently wired into `Player.gd`.
- `assets/manifests/{mage,adventurer}_body_walk{1,2}_{s,se,e,ne,n}.manifest.json` (20 manifests), `assets/source/generated/{mage,adventurer}_body_walk_sheet/source.png` (one shared 5-direction x 2-pose grid sheet per character, generated in one ChatGPT response each, addressed via `sourceCell` on a 5-col x 2-row grid), and `assets/sprites/characters/{mage,adventurer}_body_walk{1,2}_*.png`: the two new mid-stride poses per direction per character that drive the walk-cycle animation (see `Player.gd` above). `walk1`/`walk2` combine with the existing `idle` pose at runtime — no third pose was generated for "neutral", since idle already serves that role.
- `assets/manifests/{mage,adventurer}_body_idle_tier1_{s,se,e,ne,n}.manifest.json` (10 manifests), `assets/source/generated/{mage,adventurer}_body_idle_tier1_sheet/source.png` (one shared 5-direction grid sheet per character, a ChatGPT in-place edit of the base idle sheet adding leather armor), and `assets/sprites/characters/{mage,adventurer}_body_idle_tier1_*.png`: Tier 1 (Leather) armor art, see `docs/design/ARMOR_TIERS.md`. Normalized as full replacement body sprite sets (not a transparent overlay — see that doc for why the original diff-based overlay plan was dropped). Not yet wired into `Player.gd`/`Player.tscn`; no equip logic or UI exists yet.

## How to run

Open `project.godot` with Godot 4.x standard and press F5.

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
- [ ] Character panel shows equipment coming soon.
- [ ] Character panel shows "Bonuses earned: none yet" before any bonus is earned, and lists the earned badge name(s) (e.g. "Elder's Wisdom Badge") as correct learning-check answers are given.
- [ ] A correct learning-check answer's completion dialogue names the earned badge (e.g. "...You've received the Elder's Wisdom Badge.").
- [ ] Character panel's Items line lists every collected item by name (not just the original three), with an "x2" suffix if the same item is collected more than once.
- [ ] Existing Elder, Mira, and Finn quest flows still work while the character panel is opened and closed.

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
favor of reusing the existing body-art pipeline unmodified). The `Armor` node remains
hidden/empty; nothing yet grants or equips armor in-game.

Next decision is between:
- building an equip/inventory system so Tier 1 armor is actually reachable in-game
  (swap `Body`'s `sprite_frames` to the tier1 set), including a source for players to earn
  it;
- local save/load (`docs/ROADMAP.md` milestone 5);
- more story/quest content (`docs/ROADMAP.md` milestone 6).
