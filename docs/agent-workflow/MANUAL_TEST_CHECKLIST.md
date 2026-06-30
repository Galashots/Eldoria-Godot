# Manual Test Checklist

## Pre-flight: sync branch before testing

- [ ] Run `git fetch origin`.
- [ ] Check out the target branch.
- [ ] Confirm `git diff origin/<branch>` is empty unless intentionally testing local uncommitted changes.
- [ ] Confirm `git status --short` is clean except for explicitly acknowledged local artifacts.
- [ ] If the branch is stale or dirty, stop and report before continuing.

## Gameplay checklist

- [ ] Project opens in Godot 4.x.
- [ ] Main scene runs with F5.
- [ ] No parser errors appear.
- [ ] Profile selector appears at launch.
- [ ] Grade 2 selection works.
- [ ] Grade 5 selection works.
- [ ] `selected_profile` is recorded in GameState.
- [ ] HUD text changes by profile.
- [ ] Elder offer dialogue changes by profile.
- [ ] Movement works after profile selection.
- [ ] The blue player is visible.
- [ ] WASD movement works.
- [ ] Arrow-key movement works.
- [ ] The brown obstacle blocks the player.
- [ ] The purple Elder NPC is visible.
- [ ] The green Mira NPC is visible.
- [ ] The golden-star collectible is visible.
- [ ] The glowing-herb collectible is visible.
- [ ] The objective prompt is visible.
- [ ] Elder golden-star quest completes after the learning check regardless of answer; a correct answer's dialogue includes "Bonus earned!".
- [ ] After Elder quest completion, HUD points to Mira.
- [ ] Mira offers the glowing-herb objective.
- [ ] Touching the glowing herb removes it.
- [ ] GameState records `glowing_herb`.
- [ ] Returning to Mira opens the profile-aware learning check.
- [ ] Wrong answer still completes the Mira quest, with no bonus.
- [ ] Correct answer completes the Mira quest and the dialogue line includes "Bonus earned!".
- [ ] Finn is visible.
- [ ] Finn is gated until Mira completion.
- [ ] HUD points to Finn after Mira.
- [ ] Shimmering Ore is visible and collectible.
- [ ] CharacterPanel shows Shimmering Ore.
- [ ] Grade 2 Finn answer is `fish`.
- [ ] Grade 5 Finn answer is `2/4`.
- [ ] Wrong answer still completes the Finn quest, with no bonus.
- [ ] Correct answer completes the Finn quest and the dialogue line includes "Bonus earned!".
- [ ] Existing documentation has not been deleted.
