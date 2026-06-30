# Eldoria-Godot North Star

The single source of truth for *what* Eldoria-Godot is and *why*. Read this before
planning a milestone. Keep it short; if a decision contradicts this file, resolve it here
first.

## Vision

A bright, readable, family-friendly top-down fantasy RPG for Calgary/Alberta **Grade 2**
and **Grade 5** players. Children explore a small living world, help its people, and grow
stronger. Learning is woven into play and **earns bonuses — it never blocks adventure**.

## Pillars

1. **Cohesion over volume.** Beauty and depth come from a few choices that reinforce each
   other (art, traversal, quests, progression), not from more systems. Build one excellent
   thing before a second.
2. **One vertical slice.** Aim for a single cohesive slice that is genuinely fun and
   genuinely teaches, rather than a broad content plan. (See *Vertical-slice target*.)
3. **Quests are playable arcs, not quizzes in disguise.** Every quest has a fiction the
   child cares about, a real action, a non-punitive feedback loop, and a visible
   consequence in the world or character sheet.
4. **Two age profiles, one world.** Grade 2 (ages ~6–8) and Grade 5 (ages ~9–12) play the
   same fiction with different scaffolding, text density, and challenge — not two games.
5. **Every short session yields permanent progress.** A 10–15 minute play should always
   leave behind something: world knowledge, a keepsake/cosmetic, a codex entry, or a
   mastery marker.

## Core rule: learning never gates adventure

Carried over from Eldoria-V2 (`docs/v2-reference/README.md`) and reinforced by the
curriculum research (`docs/design/RESEARCH_NOTES.md`):

> Learning creates **bonuses only** — extra reward, cosmetics, convenience. Players can
> always explore, talk, retry, and finish quests **without answering correctly**.

**Current build does not yet follow this rule.** The Elder/Mira/Finn learning checks
*gate* quest completion (a wrong answer stalls the quest on "Try again."). The agreed next
gameplay change is to **realign to bonus-only**: keep the explicit two-choice quiz format,
but let a wrong or skipped answer still complete the quest, with a **correct answer
granting a bonus** (e.g. extra item, cosmetic, or a mastery mark). See
`docs/design/CURRICULUM_MAP.md` for how this maps onto the existing quests.

## Vertical-slice target (staged, medium-term)

The finished slice — built up over several milestones, not at once:

- one **village hub** with a few service loops (quest giver, character panel, later crafting/codex),
- one **wilderness zone** with visible landmarks and at least one optional route,
- one short **dungeon** that teaches a verb and recombines it,
- a **home-base loop** where progress is visible (cosmetics / keepsakes),
- the **two quest chains** (Grade 2 and Grade 5 framings of shared fiction).

The current three-quest loop (Elder → Mira → Finn) is the **seed** of the village hub, not
the finished slice. Grow it deliberately; resist "feature equity" across many NPCs/biomes.

## Non-goals (for now)

Carried from `docs/agent-workflow/V2_TO_GODOT_PORT_RULES.md`. Not forbidden forever — just
not part of the current trajectory:

- save/load depth, inventory/equipment depth, combat depth;
- a full curriculum bank or `.tres`-driven content architecture;
- procedural systems;
- accounts, login, cloud, analytics, ads, external APIs;
- any open text/voice chat or user-generated public content.

## Safety posture

- Target **ESRB E10+** (an RPG with monsters/mild combat is usually E10+, not E).
- **COPPA-minded:** assume players may be under 13 — data minimization, no unnecessary
  collection. Consistent with the existing "no accounts/analytics" non-goal.
- **No open chat** of any kind in the base product.
- Tooling is **adult-operated**: the consumer AI services used to build Eldoria
  (Claude, Gemini/Antigravity, ChatGPT/Codex) are 18+. Kids play the *game*, not the tools.

## Where this fits

- `docs/design/CURRICULUM_MAP.md` — the learning spine (profiles, subjects, quest mapping).
- `docs/design/VISUAL_CONTRACT.md` — the art/technical decisions to lock now.
- `docs/design/RESEARCH_NOTES.md` — what the five research docs are good (and not good) for.
- `AGENTS.md`, `docs/GODOT_SPIKE_DECISIONS.md` — durable operating rules; this file is the
  product vision they serve.
