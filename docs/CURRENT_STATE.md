# Current State

## Status

Milestones 1 through 8 are complete and pushed. Milestone 9, character/inventory popup placeholder, is implemented in a PR and ready for review/QA.

## Implemented files

- `project.godot`: project configuration, main scene, and GameState autoload.
- `scenes/main/Main.tscn`: green floor, brown collision obstacle, player, Elder, Mira, collectibles, HUD, dialogue, character panel, profile selector, and learning check instances.
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
- `scenes/ui/CharacterPanel.tscn` and `scripts/ui/CharacterPanel.gd`: placeholder character/inventory popup opened with C or I.
- `assets/README.md` and `assets/sprites/README.md`: asset folder structure guidance.
- `assets/source/.gdignore` and `assets/source/README.md`: ignored source/reference material area.
- `docs/art/ASSET_PIPELINE.md` and `docs/art/STYLE_GUIDE.md`: first art workflow and visual rules.

## How to run

Open `project.godot` with Godot 4.x standard and press F5.

## Manual test checklist

- [ ] Project opens without parser errors.
- [ ] F5 runs `Main.tscn`.
- [ ] Profile selector appears at launch, blocking movement and interaction.
- [ ] Grade 2 selection works (Button or Key 2).
- [ ] Grade 5 selection works (Button or Key 5).
- [ ] Pressing C or I after profile selection opens/closes the character panel.
- [ ] Character panel shows selected profile.
- [ ] Character panel shows current quest summary.
- [ ] Character panel shows collected items after the golden star and glowing herb are collected.
- [ ] Character panel shows equipment coming soon.
- [ ] Existing Elder and Mira quest flows still work.
- [ ] Existing documentation remains present.

## Next milestone

Move one content type toward data-driven definitions or begin first real asset replacement pass.
