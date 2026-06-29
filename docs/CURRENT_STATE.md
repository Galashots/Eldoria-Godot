# Current State

## Status

Milestones 1, 2, and 3 are complete and pushed. Milestone 4, grade profile selector placeholder and profile-aware objective/dialogue text, is implemented and ready for QA.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, and player instance.
- `scenes/player/Player.tscn`: blue placeholder player, collision shape, and camera.
- `scripts/core/GameState.gd`: minimal profile, health, and collected-item state.
- `scripts/player/Player.gd`: WASD and arrow-key movement.
- `scenes/npcs/Elder.tscn` and `scripts/npcs/Elder.gd`: purple Elder placeholder with collision.
- `scenes/items/Collectible.tscn` and `scripts/items/Collectible.gd`: golden-star pickup that records collection in GameState.
- `scripts/ui/HUD.gd`: visible objective text that updates based on the selected profile and quest state.
- `scenes/ui/DialogueBox.tscn` and `scripts/ui/DialogueBox.gd`: reusable speaker/message UI dismissed with E, Enter, or Space.
- `scenes/ui/ProfileSelect.tscn` and `scripts/ui/ProfileSelect.gd`: profile selector overlay UI and logic.
- `scripts/npcs/Elder.gd`: proximity prompt and profile-aware dialogue for offering and completing the golden-star objective.
- `scripts/core/GameState.gd`: Elder quest started/completed state, selected profile state, and update signals.

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
- [ ] Talking to the Elder again completes the quest.
- [ ] The dialogue and objective show the completed state.
- [ ] Existing documentation remains present.

## Next milestone

Evaluate the completed vertical slice and choose the next smallest milestone without adding combat, save/load, or curriculum systems by default.
