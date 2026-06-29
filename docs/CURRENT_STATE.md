# Current State

## Status

Milestones 1 through 4 are complete and pushed. Milestone 5, a tiny profile-aware learning check placeholder before Elder quest completion, is implemented in a PR and ready for review/QA.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, player, Elder, collectible, HUD, dialogue, profile selector, and learning check instances.
- `scenes/player/Player.tscn`: blue placeholder player, collision shape, and camera.
- `scripts/core/GameState.gd`: minimal profile, health, collected-item, and Elder quest state.
- `scripts/player/Player.gd`: WASD and arrow-key movement blocked until profile selection.
- `scenes/npcs/Elder.tscn` and `scripts/npcs/Elder.gd`: purple Elder placeholder with collision, proximity prompt, profile-aware dialogue, and learning-check request.
- `scenes/items/Collectible.tscn` and `scripts/items/Collectible.gd`: golden-star pickup that records collection in GameState.
- `scripts/ui/HUD.gd`: visible objective text that updates based on the selected profile and quest state.
- `scenes/ui/DialogueBox.tscn` and `scripts/ui/DialogueBox.gd`: reusable speaker/message UI dismissed with E, Enter, or Space.
- `scenes/ui/ProfileSelect.tscn` and `scripts/ui/ProfileSelect.gd`: profile selector overlay UI and logic.
- `scenes/ui/LearningCheck.tscn` and `scripts/ui/LearningCheck.gd`: tiny profile-aware two-choice learning check before quest completion.

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
- [ ] Green floor, blue player, and brown obstacle are visible.
- [ ] The player cannot pass through the obstacle.
- [ ] The golden-star collectible is visible.
- [ ] Approaching the Elder shows `Press E to talk`.
- [ ] E opens the dialogue request to find the golden star.
- [ ] E, Enter, or Space closes dialogue.
- [ ] Touching the star removes it and records `golden_star` in GameState.
- [ ] The objective updates to return to Elder Rowan.
- [ ] Returning to the Elder opens the profile-aware learning check.
- [ ] Wrong answer shows `Try again.` and does not complete the quest.
- [ ] Correct answer completes the quest.
- [ ] The dialogue and objective show the completed state.
- [ ] Existing documentation remains present.

## Next milestone

Evaluate the completed vertical slice and choose the next smallest milestone without adding combat, save/load, or curriculum systems by default.
