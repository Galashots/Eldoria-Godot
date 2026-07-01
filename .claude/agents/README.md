# Subagent suite & the autonomous expansion loop

This directory defines a small suite of Claude Code subagents that let a **Sonnet 5
orchestrator session** run a continuous, mostly-autonomous game-expansion loop for
Eldoria-Godot, with an **Opus architect** doing the planning.

Each subagent starts with a **fresh, isolated context** — it cannot see the orchestrator's
conversation or another agent's. That's why every agent's prompt opens by telling it to read
`AGENTS.md`, `docs/CURRENT_STATE.md`, and `docs/design/NORTH_STAR.md` (plus its job-specific
docs) before acting, and closes with the `AGENTS.md` report format (files changed; run/test
steps; assumptions; risks; exact next step).

## The agents

| Agent | Model | Role | Writes? |
| --- | --- | --- | --- |
| `game-architect` | **opus** | Research 2D-RPG design + own `docs/design/EXPANSION_BACKLOG.md` | repo (docs) |
| `gdscript-implementer` | sonnet | Build ONE top-ready backlog slice as a tiny change | repo (code + docs) |
| `gdscript-test-runner` | sonnet | Run the headless GDScript suite, report PASS/FAIL | no (read-only) |
| `pr-auditor` | sonnet | Run the AGENTS.md PR-audit + boundary/pillar review | no (read-only) |
| `docs-keeper` | sonnet | Keep CURRENT_STATE / ROADMAP / backlog statuses truthful | repo (docs only) |
| `asset-normalizer` | sonnet | Drive `tools/asset_pipeline/` when a slice needs real art | repo (assets) |

Every agent uses `model: sonnet` **except `game-architect`, which uses `model: opus`** (the
planning brain thinks; the workers act).

## The loop

The **main session runs on Sonnet 5 as the conductor.** It:

1. Calls **`game-architect` (Opus)** to research and refill/re-prioritize the backlog. The
   architect writes sourced findings into `docs/design/RESEARCH_NOTES.md` and a prioritized
   queue of small slices into `docs/design/EXPANSION_BACKLOG.md`.
2. Takes the single top **`ready`** slice and sequences the workers to build it:
   `gdscript-implementer` → `gdscript-test-runner` → `pr-auditor` → `docs-keeper`
   (inserting `asset-normalizer` before the implementer when the slice needs real art).
3. Opens a PR for the completed slice, then loops back to step 1.

## Hard rules for the conductor

- **Subagents cannot spawn subagents.** All orchestration lives in the main session — the
  conductor is the only thing that sequences agents. Each agent does its one job and reports
  back.
- **The engine NEVER auto-merges and NEVER pushes to `main`.** It opens PRs; a human reviews
  and merges. New work branches off current `origin/main` (branch hygiene in `AGENTS.md`).
- **HALT on `blocked: needs-user-input`.** If the top backlog item (or the architect's report)
  is flagged `blocked: needs-user-input` — e.g. the unconfirmed subject-scope table in
  `docs/design/CURRICULUM_MAP.md` before a 5th quest — the loop stops and surfaces the exact
  question to the user instead of guessing.
- **Parallelize only across disjoint files.** Godot `.tscn`/`.tres` scene and resource files
  merge badly (especially large embedded scenes like `scenes/main/Main.tscn`), so never run
  two agents that could touch the same scene/resource at once. When in doubt, run serially.
- **One tiny slice per PR.** Keep changes small and reviewable, matching the M1–M4 precedent.

## Adding or changing agents

Keep each agent single-purpose, keep the "read the live docs first / report in AGENTS.md
format last" bookends, and set `model:` per the policy above. Don't give read-only agents
(`gdscript-test-runner`, `pr-auditor`) write tools.
