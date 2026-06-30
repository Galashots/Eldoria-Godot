# Curriculum Map

How learning is woven into Eldoria-Godot. This is the design spine; it does not yet
prescribe a `.tres` curriculum engine (that stays a non-goal — see
`docs/design/NORTH_STAR.md`).

## Two presentation profiles

The same world and fiction, scaffolded differently. Aligns with the existing
`grade_2_mage` / `grade_5_adventurer` profiles in `scripts/core/GameState.gd`.

| Profile | Typical age band | Presentation |
| --- | --- | --- |
| **Grade 2 Mage** | ~6–8 | Shorter, plainer text; more visual/audio scaffold; one idea per line; larger targets; read-aloud-friendly. |
| **Grade 5 Adventurer** | ~9–12 | More text; planning, comparison, and written/word-choice challenges layered on the same fiction. |

Age bands follow NN/g guidance to design for narrow age groups rather than one generic
"kid mode" (`docs/design/RESEARCH_NOTES.md`).

## Three layers per quest

Every educational quest is authored on three layers:

1. **Fiction goal** — what the child *wants* to do (help Elder Rowan, restore the garden).
2. **Curricular competency** — the underlying skill it exercises.
3. **Evidence signal** — what the child's actions/answers tell us about understanding.

…wrapped in a **non-punitive, bonus-only feedback loop** (see below).

## Feedback rule (bonus-only)

Per the North Star core rule:

- A quest **always completes** once the fiction action is done (item returned, route
  chosen), regardless of the learning-check answer.
- A **correct** answer grants a **bonus** (extra reward, cosmetic, or a per-skill mastery
  mark). A wrong/skipped answer is fine — gentle "not quite, here's why," then continue.
- Explicit two-choice quiz format is kept **for now** (user decision this session). The
  bonus-only realignment is a *gameplay* change tracked in `docs/CURRENT_STATE.md`; this
  doc defines the target behavior.

## Proposed subject scope — CONFIRM/ADJUST

The original research did not pin exact subjects; this is a grounded default derived from
what the build already encodes plus the curriculum guide's suggestion. **Confirm or change
before it drives content.**

| Profile | Primary | Secondary | Later expansion |
| --- | --- | --- | --- |
| Grade 2 | Early **numeracy** (number sense, money, estimation) | Early **literacy** (rhyme, phonics) | Science/social observation |
| Grade 5 | **Numeracy** (multiplication, fractions) | **Literacy** (word choice / ELA) | Science (climate, regions) & social studies |

Exact **Alberta outcome codes are `TODO`** — to be pinned once subjects are confirmed. The
curriculum guide flags these as unspecified and recommends, most likely, *Grade 2 math +
Grade 5 science/social + cross-grade literacy*.

## Existing quests mapped (nothing already built is lost)

The current Elder → Mira → Finn checks already fit this scheme:

| Quest | Fiction goal | Competency (G2 / G5) | Current check (G2 / G5) |
| --- | --- | --- | --- |
| **Elder — golden star** | Recover the golden star for Elder Rowan | Number sense / multiplication | "Which is bigger, 7 or 4?" / "6 × 7 = ?" |
| **Mira — glowing herb** | Restore the garden | Phonemic awareness / word choice | "Rhymes with star?" / "Which verb is stronger?" |
| **Finn — shimmering ore** | Supply the forge (gated after Mira) | Phonics / fractions | "Starts like *forge*?" / "Equal to 1/2?" |

**Realignment note:** today these checks gate completion. Under the bonus-only target,
each quest completes on item return; the check becomes the bonus step.

## Stealth assessment (future direction, not now)

The curriculum guide's stronger model is *evidence-centered / stealth* assessment — infer
understanding from in-fiction actions (pay correct change, pick the safe route) rather than
asking outright. Kept explicit-quiz for now by user decision; revisit when designing new
quests. Capture per-skill **mastery marks** as the bridge: they work with explicit checks
today and with stealth signals later.
