# Visual Contract

The art/technical decisions worth **locking now** because they are cheap to choose early
and expensive to retrofit. This is the *decisions* layer; the *how-to* lives in
`docs/art/STYLE_GUIDE.md` and `docs/art/ASSET_PIPELINE.md`. Where they overlap, those files
and this one already agree — this file just makes the numbers explicit and authoritative.

Distilled from the Visual Design Guide (PDF) and reconciled with Eldoria-V2, which already
authored its hero at **32×48 cells with 6-frame directional walks** — so these targets
match real prior art, not just theory.

## Lock now

| Decision | Value | Notes |
| --- | --- | --- |
| Logical resolution | **640×360** | Integer-scales cleanly to 720p/1080p/1440p/2160p. (Project window is currently 1280×720; revisit a `viewport` stretch when real art lands.) |
| Scaling | Integer / nearest where possible | Letterbox on odd mobile aspect ratios. |
| Tile grid | **16×16** | Author entities against this grid for cohesion. |
| Actor canvas | **32×48** (standard human) | Footprint ~16×16; pivot at center-bottom. Matches V2 hero + `ASSET_PIPELINE.md`. |
| Item / icon | 16×16 or 32×32 | Per `ASSET_PIPELINE.md`. |
| Texture filter | **Nearest-neighbor**, no mipmaps | Keep pixel art crisp. |
| Palette | One **limited master palette**, biome/material sub-palettes | No per-asset ad-hoc colors. Readability-first. |
| Naming | `snake_case`, descriptive prefixes | e.g. `npc_mira_idle.png`, `item_glowing_herb.png`. Already in `ASSET_PIPELINE.md`. |
| Light direction | Single, upper-left | Consistent across gameplay sprites. |

## Frame-count / timing starting targets

Starting points, not hard rules — tune in-engine:

| Anim | Frames | Feel |
| --- | --- | --- |
| Idle | 4–6 | small breathing / blink |
| Walk | 6–8 | exploration default |
| (later) attack | 6–8 | anticipation → contact → recovery |
| Hurt | 2–4 | snap, don't linger |

## Defer until content volume justifies it

The Visual Design Guide proposes a much heavier production pipeline. **Do not adopt these
yet** — they pay off only with a large asset count, and the project is still mostly
placeholder polygons:

- texture **atlas families** (characters / fx / per-biome / ui);
- per-asset **JSON metadata sidecars** *loaded by the game at runtime* (canonical IDs,
  pivots, hitbox/hurtbox metadata) — distinct from the build-time normalization manifests
  in `assets/manifests/` (see `docs/art/ASSET_NORMALIZATION_PIPELINE.md`), which are a
  dev-tooling input never loaded by Godot and are already in use;
- asset / palette / animation **registries**;
- skeletal / cutout rigs (stay **frame-by-frame** for now).

When real art volume arrives, revisit these via the Visual Design Guide (see
`docs/design/RESEARCH_NOTES.md` for its caveats — it is Unity-leaning and was written
without the actual Eldoria style in hand).

## Relationship to existing art docs

- `docs/art/STYLE_GUIDE.md` — visual direction, placeholder color language, acceptance
  checklist. **Unchanged.**
- `docs/art/ASSET_PIPELINE.md` — folder layout, naming, source-vs-export, import hygiene,
  small art PRs. **Unchanged.**
- This file — the numeric/technical decisions those workflows assume. If a number here ever
  conflicts with those files, update both together.
