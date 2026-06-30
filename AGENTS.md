# Agent Guidance

## Project boundaries

- Use Godot 4.x standard, GDScript, and Godot-native scenes and nodes.
- Build a single-player, local-first game.
- Do not add accounts, analytics, ads, external APIs, cloud saves, or personal data.
- Do not attempt a full Eldoria-V2 port yet; treat V2 as read-only reference.
- Use placeholder art first and build small vertical slices.
- Do not touch unrelated files.
- For the current lightweight data approach, add new quest, item, and profile display text through `scripts/core/ContentDefinitions.gd`; defer `.tres` resource migration until the pattern is proven by more content.

## Required workflow

Before work, read this file, `docs/CURRENT_STATE.md`, `docs/GODOT_SPIKE_DECISIONS.md`, and the relevant files in `docs/agent-workflow/`.

After every task, report:

- files changed;
- run and test steps;
- assumptions;
- risks;
- the exact next step.

## PR audit and playtest

Before auditing, validating, or playtesting a PR branch:

1. Run `git fetch origin`.
2. Check out the target branch.
3. Compare the local branch against `origin/<branch>` and confirm `git diff origin/<branch>` is empty unless intentionally testing local uncommitted changes.
4. Confirm `git status --short` is clean except for explicitly acknowledged local artifacts.
5. If the branch is stale or dirty, stop and report before continuing.
