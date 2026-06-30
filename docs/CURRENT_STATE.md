# Current State

## Status

Milestones 1 through 12 are complete and merged: the PR branch-sync docs rule, the `docs/design/` north-star doc set, and the bonus-only realignment of the Elder/Mira/Finn learning checks.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `AGENTS.md`: project and agent workflow guidance, including the current `ContentDefinitions.gd` rule for lightweight quest/item/profile display text.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, player, Elder, Mira, Finn, collectibles, HUD, dialogue, character panel, profile selector, and learning check instances.
- `scenes/player/Player.tscn`: blue placeholder player, collision shape, and camera.
- `scripts/core/GameState.gd`: minimal profile, health, collected-item, reusable quest state, and Elder compatibility flags.
- `scripts/core/ContentDefinitions.gd`: tiny lookup layer for profile labels, item labels, and quest summaries.
- `scripts/player/Player.gd`: WASD and arrow-key movement blocked until profile selection.
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
- `scenes/ui/CharacterPanel.tscn` and `scripts/ui/CharacterPanel.gd`: placeholder character/inventory popup opened with C or I and backed by content definitions.
- `assets/README.md` and `assets/sprites/README.md`: asset folder structure guidance.
- `assets/source/.gdignore` and `assets/source/README.md`: ignored source/reference material area.
- `docs/art/ASSET_PIPELINE.md` and `docs/art/STYLE_GUIDE.md`: first art workflow and visual rules.

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
- [ ] Green floor, blue player, brown obstacle, Elder, Mira, Finn, golden star, glowing herb, and shimmering ore are visible.
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

Next decision is between:
- surfacing earned bonuses somewhere the player can see (HUD or character panel);
- tiny Godot Resource experiment for quest/item definitions;
- first real asset replacement pass;
- inventory/reward foundation.
