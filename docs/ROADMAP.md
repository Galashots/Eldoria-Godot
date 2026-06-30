# Roadmap

## Current baseline
- Elder → Mira → Finn placeholder vertical slice.
- Two child profiles: Grade 2 Mage and Grade 5 Adventurer.
- Local-first, single-player, no accounts, no analytics, no ads.
- Placeholder art-first.
- `ContentDefinitions.gd` currently owns lightweight display text.

## Near milestones
1. Keep current-state docs truthful after each merge.
2. ~~Run a tiny Resource experiment for quest/item definitions.~~ Done — item display
   labels are now `ItemDefinition` `.tres` resources under `data/items/`; quest summaries
   and profile labels stay as dictionaries in `ContentDefinitions.gd` for now.
3. Run the first real *production* asset replacement pass — the pipeline pass is proven
   (one test sprite went source -> manifest -> normalize -> validate -> `Player.tscn` and
   runs cleanly), so this is now about generating approved hero/armor art, not the tool.
   See `docs/art/ASSET_NORMALIZATION_PIPELINE.md`. Both Grade 2 Mage and Grade 5
   Adventurer now have production art with 8-direction movement-facing.
4. ~~Add inventory/reward foundation.~~ Done — the character panel's item list is generic
   (any `GameState.collected_items` entry, with quantity), and learning-check bonuses are
   named badges (`ContentDefinitions.BADGE_LABELS`) shown in both the completion dialogue
   and the character panel, instead of an anonymous flag/count.
5. Add local save/load.
6. Add more story/quest content.
7. Plan iPad/web playtest/export path.

## Architecture rules
- Every milestone must preserve the playable slice.
- Prefer tiny PRs.
- Do not introduce EventBus until signals become unmanageable.
- Resource experiment proven (see milestone 2) for item definitions specifically — do not
  migrate quest summaries or profile labels to `.tres` until there's a concrete reason to.
- Asset pipeline pass proven (see milestone 3) — production asset replacement may scale.
