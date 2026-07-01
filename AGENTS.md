# Agent Guidance

## Project boundaries

- Use Godot 4.x standard, GDScript, and Godot-native scenes and nodes for the shipped game.
  Offline dev tooling that never ships in the Godot project (e.g. `tools/asset_pipeline/`)
  may use another language where it's a clearly better fit; see
  `docs/art/ASSET_NORMALIZATION_PIPELINE.md` for the precedent.
- Build a single-player, local-first game.
- Do not add accounts, analytics, ads, external APIs, cloud saves, or personal data.
- Do not attempt a full Eldoria-V2 port yet; treat V2 as read-only reference.
- Use placeholder art first and build small vertical slices.
- Do not touch unrelated files.
- Item display labels are `ItemDefinition` (`scripts/core/ItemDefinition.gd`) `Resource` instances under `data/items/*.tres`, loaded by `ContentDefinitions.get_item_label()` — this is the proven Resource-backed content pattern (`docs/ROADMAP.md` milestone 2). Quest summaries and profile display text still go through the lightweight dictionary approach in `scripts/core/ContentDefinitions.gd`; defer migrating those to `.tres` until there's a real reason to (more content, or a second consumer needing structured data), not just for consistency with items.
- An optional, locally-installed `godot-ai` MCP editor plugin (`addons/godot_ai/`, gitignored) may add an `_mcp_game_helper` autoload and an `[editor_plugins]` entry to a contributor's local `project.godot`. Those two lines are local-only — never commit them, since `addons/godot_ai/` isn't in the repo and committing them would break the project for anyone without that addon installed.

## Required workflow

Before work, read this file, `docs/design/NORTH_STAR.md`, `docs/CURRENT_STATE.md`, `docs/GODOT_SPIKE_DECISIONS.md`, and the relevant files in `docs/agent-workflow/`.

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

## Branch hygiene

Multiple AI tools work on this repo independently, so the same milestone can get started on more than one branch without anyone noticing. Before starting new work:

1. Run `git fetch origin` and check `gh pr list --state all` (or `git branch -r`) for an existing branch or PR already covering the same change.
2. Base new branches on current `origin/main`, not on an older local branch.

After a branch's PR merges, or its work is confirmed superseded by something already on `main`, delete the branch (`git push origin --delete <branch>`) so the branch list stays current.

## Subagents & expansion loop

A Claude Code subagent suite lives in `.claude/agents/` for running a mostly-autonomous
game-expansion loop: an Opus `game-architect` researches design and maintains the prioritized
queue in `docs/design/EXPANSION_BACKLOG.md`, and Sonnet workers (`gdscript-implementer`,
`gdscript-test-runner`, `pr-auditor`, `docs-keeper`, `asset-normalizer`) build the top slice.
See `.claude/agents/README.md` for how the loop is sequenced. Key rules that bind any tool:
the loop **never auto-merges or pushes to `main`** (it opens PRs for human review), it **halts
on any backlog item marked `blocked: needs-user-input`** (e.g. the unconfirmed subject-scope
table in `docs/design/CURRICULUM_MAP.md`), and it keeps one tiny slice per PR.
