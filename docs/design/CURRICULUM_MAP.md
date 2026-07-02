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

## Feedback rule (bonus-only) — implemented

Per the North Star core rule, and now live in `scripts/ui/LearningCheck.gd`:

- A quest **always completes** once the fiction action is done (item returned), regardless
  of the learning-check answer.
- A **correct** answer calls `GameState.award_quest_bonus()` and the completion dialogue
  says "Bonus earned!" — today that's the entire bonus (a flag plus a line of text), not
  yet a tangible extra reward, cosmetic, or per-skill mastery mark. Turning the bonus into
  something the player can see/keep is open design work (see `docs/CURRENT_STATE.md`
  "Next milestone").
- Explicit two-choice quiz format is kept **for now** (user decision this session).

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
| **Yarrow — silverleaf** | Brew a remedy for villagers ill from the well (gated after Finn) | Money/number sense / word choice | "The remedy jar costs a dime. Which coin do you hand me?" / "Which word means someone who helps others?" |

**Yarrow was added deliberately narrow**, not as a template for indefinite expansion: same
village hub, same linear gate chain, and the *already-confirmed* numeracy/literacy subjects
above — no new subject was picked. The "Proposed subject scope — CONFIRM/ADJUST" table
below is still unconfirmed; a fifth quest should get user input on subject scope rather than
defaulting to numeracy/literacy again, per `docs/design/NORTH_STAR.md`'s "resist feature
equity across many NPCs/biomes" pillar.

**Stealthier numeracy (expansion backlog, format-only change):** Yarrow's Grade 2 check was
reworded from an abstract "Which coin is worth more?" prompt into the same coin-comparison
competency expressed as an in-fiction action — paying for the remedy jar with the correct
coin — per `docs/design/RESEARCH_NOTES.md` §8.2's intrinsic-integration principle. The
underlying competency (G2 money/number sense) and the two-choice mechanic are unchanged; only
the fiction wrapping the choice changed, so this does **not** touch the CONFIRM-gated subject
table above.

**Realignment note:** implemented — each quest completes on item return; the check is the
bonus step, not a gate.

**Count-out-the-coins at the Merchant (expansion backlog, format-only change):** extends the
same Yarrow "pay the right coin" reframe to the `ShopUI` weapon purchase flow, per
`docs/design/RESEARCH_NOTES.md` §9.2's intrinsic-integration principle. Buying a weapon always
completes first; an optional bonus beat then lets the child count out coins matching the
price (G2: any set of coins summing to the price; G5: the fewest-coins solution). Same
already-confirmed G2/G5 money/number-sense competency as Yarrow's check — no new subject, no
new quest — so this also does **not** touch the CONFIRM-gated subject table above. Skipping or
answering wrong never blocks or undoes the purchase; a correct answer adds one bonus coin.

## Stealth assessment (future direction, not now)

The curriculum guide's stronger model is *evidence-centered / stealth* assessment — infer
understanding from in-fiction actions (pay correct change, pick the safe route) rather than
asking outright. Kept explicit-quiz for now by user decision; revisit when designing new
quests. Capture per-skill **mastery marks** as the bridge: they work with explicit checks
today and with stealth signals later.
