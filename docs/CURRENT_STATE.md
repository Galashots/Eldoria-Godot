# Current State

## Status

Milestones 1 through 6 are complete and pushed. Milestone 7, Mira the Gardener and a second tiny profile-aware quest, is implemented in a PR and ready for review/QA.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, player, Elder, Mira, collectibles, HUD, dialogue, profile selector, and learning check instances.
- `scenes/player/Player.tscn`: blue placeholder player, collision shape, and camera.
- `scripts/core/GameState.gd`: minimal profile, health, collected-item, reusable quest state, and Elder compatibility flags.
- `scripts/player/Player.gd`: WASD and arrow-key movement blocked until profile selection.
- `scenes/npcs/Elder.tscn` and `scripts/npcs/Elder.gd`: purple Elder placeholder with golden-star quest.
- `scenes/npcs/Mira.tscn` and `scripts/npcs/Mira.gd`: green gardener NPC with glowing-herb quest.
- `scenes/items/Collectible.tscn` and `scripts/items/Collectible.gd`: reusable pickup logic.
- `scenes/items/GlowingHerb.tscn`: glowing-herb pickup for Mira's quest.
- `scripts/ui/HUD.gd`: visible objective text that updates based on selected profile and active quest state.
- `scenes/ui/DialogueBox.tscn` and `scripts/ui/DialogueBox.gd`: reusable speaker/message UI dismissed with E, Enter, or Space.
- `scenes/ui/ProfileSelect.tscn` and `scripts/ui/ProfileSelect.gd`: profile selector overlay UI and logic.
- `scenes/ui/LearningCheck.tscn` and `scripts/ui/LearningCheck.gd`: reusable profile-aware two-choice learning check.

## How to run

Open `project.godot` with Godot 4.x standard and press F5.

## Manual test checklist

- [ ] Project opens without parser errors.
- [ ] F5 runs `Main.tscn`.
- [ ] Profile selector appears at launch, blocking movement and interaction.
- [ ] Grade 2 selection works (Button or Key 2).
- [ ] Grade 5 selection works (Button or Key 5).
- [ ] `selected_profile` is recorded in GameState.
- [ ] HUD text changes by profile.
- [ ] Elder offer dialogue changes by profile.
- [ ] Movement works after profile selection.
- [ ] Green floor, blue player, brown obstacle, Elder, Mira, golden star, and glowing herb are visible.
- [ ] The player cannot pass through the obstacle.
- [ ] Elder golden-star quest still completes after the learning check.
- [ ] After Elder quest completes, HUD points to Mira.
- [ ] Mira offers the glowing-herb quest.
- [ ] Touching the glowing herb removes it and records `glowing_herb` in GameState.
- [ ] Returning to Mira opens the profile-aware learning check.
- [ ] Wrong answer shows `Try again.` and does not complete the Mira quest.
- [ ] Correct answer completes the Mira quest.
- [ ] Existing documentation remains present.

## Next milestone

Add asset pipeline foundation, then add character/inventory popup placeholder.
