# Roadmap

## Current baseline
- Elder → Mira → Finn placeholder vertical slice.
- Two child profiles: Grade 2 Mage and Grade 5 Adventurer.
- Local-first, single-player, no accounts, no analytics, no ads.
- Placeholder art-first.
- `ContentDefinitions.gd` currently owns lightweight display text.

## Near milestones
1. Keep current-state docs truthful after each merge.
2. Run a tiny Resource experiment for quest/item definitions.
3. Run the first real asset replacement pass — unblocked: `tools/asset_pipeline/` now
   normalizes AI-generated source art into Godot-ready sprites, see
   `docs/art/ASSET_NORMALIZATION_PIPELINE.md`.
4. Add inventory/reward foundation.
5. Add local save/load.
6. Add more story/quest content.
7. Plan iPad/web playtest/export path.

## Architecture rules
- Every milestone must preserve the playable slice.
- Prefer tiny PRs.
- Do not introduce EventBus until signals become unmanageable.
- Do not migrate all content to `.tres` until one tiny Resource experiment proves the pattern.
- Do not scale asset replacement until one asset pipeline pass is proven.
