# Asset Normalization Pipeline

ChatGPT/Gemini source art is **source art, not a final runtime asset**. It comes in
whatever resolution the tool feels like, on an unreliable background, and downscaling it
naively loses detail. This pipeline turns an approved source image into an exact,
correctly-sized, transparent PNG for `assets/sprites/`.

## Pipeline rule

```text
AI source image -> manifest -> normalize -> validate -> repo asset
```

The tool lives in `tools/asset_pipeline/` (Python). It is dev-only tooling — it runs
offline and produces committed PNGs; it is not part of the shipped Godot project and does
not change the GDScript/Godot-native boundary in `AGENTS.md`.

Install once: `pip install -r tools/asset_pipeline/requirements.txt` (Pillow + numpy).

## Commands

```bash
python tools/asset_pipeline/normalize.py --manifest <path>
python tools/asset_pipeline/validate.py --manifest <path>
python tools/asset_pipeline/test_pipeline.py
```

## What the normalizer does

- Reads a manifest declaring a target grid (`cellPx`, `cols`, `rows`) and one or more
  source images.
- Extracts each frame from its source (a grid cell or an explicit rectangle).
- Removes the background: `alpha` (source already has real transparency), `color_key`
  (strip every pixel matching a color within a tolerance), or `edge_flood_color_key`
  (strip only key-colored pixels connected to the frame's own edge — an enclosed
  same-colored detail inside the sprite, like a gem or an eye, survives).
- Alpha-trims to the sprite's actual bounds, then downscales to fit the target cell with a
  **high-quality Lanczos resample on alpha-premultiplied color** (not nearest-neighbor —
  see "Why Lanczos, not nearest-neighbor" below), then pastes at the requested anchor
  (`center`, `center_bottom`, or `top_left`).
- Writes one packed PNG sheet.

Out of scope, same as the prior pipeline this was adapted from: automatic object
segmentation, background guessing, AI-style correction, animation timing, Godot scene
integration. Source art must use true transparency or a deliberate, flat color key.

## Why Lanczos, not nearest-neighbor

Godot's import filter is locked to nearest-neighbor (`docs/design/VISUAL_CONTRACT.md`) —
correct for crisp *display-time* scaling of an already-small sprite. It is the wrong
algorithm for the one-time *downsample* from a ~1024px AI render to a 32–128px cell:
nearest-neighbor point-samples and discards most of the source detail, which is why an
earlier version of this pipeline (in the `eldoria-v2` reference repo) showed visible
quality loss after shrinking. This pipeline premultiplies alpha, resizes with Lanczos
(averages detail down instead of discarding it, and avoids dark/light fringing at
transparent edges), then un-premultiplies.

## Manifest schema

```json
{
  "version": 1,
  "id": "hero_body_idle_s",
  "target": {
    "outputPath": "../sprites/characters/hero_body_idle_s.png",
    "cellPx": [32, 48],
    "cols": 4,
    "rows": 1,
    "inherits": null,
    "expectedEmptyCells": []
  },
  "sources": {
    "source_sheet": {
      "path": "../source/generated/hero_body_idle_s/source.png",
      "grid": { "cols": 4, "rows": 1 },
      "background": { "mode": "color_key", "color": "#ff00ff", "tolerance": 24 }
    }
  },
  "frames": [
    { "sourceRef": "source_sheet", "sourceCell": [0, 0], "destCell": [0, 0], "trim": "alpha", "fit": "contain", "anchor": "center_bottom" }
  ]
}
```

- `target.cellPx` / `cols` / `rows` — output sheet is `cellPx[0]*cols` x `cellPx[1]*rows`.
- `target.inherits` (optional) — a relative path to another manifest. The armor layer's
  `cellPx`/`cols`/`rows` must match the inherited body manifest's exactly, or validation
  fails. This is how an armor overlay is guaranteed to line up frame-for-frame with the
  body it's drawn over — without a separate metadata-sidecar file (those stay deferred
  per `docs/design/VISUAL_CONTRACT.md`; this manifest is a build-time input to our own
  offline tool, never loaded by the game at runtime).
- `sources.<ref>.grid` — for a sheet source, lets frames address cells via `sourceCell`
  instead of an explicit `sourceRect`.
- `frames[].trim` — `alpha` (default, crop to non-transparent bounds) or `none`.
- `frames[].anchor` — `center`, `center_bottom` (default; matches the actor pivot
  convention in `VISUAL_CONTRACT.md`), or `top_left`.

## Naming convention

`<entity>_<layer>_<animation>_<direction>`, e.g. `hero_body_idle_s`,
`hero_armor_iron_idle_s`. Add `_v002` etc. only when re-issuing a previously shipped
asset. This stays closer to the existing `snake_case` convention in `ASSET_PIPELINE.md`
than a heavier domain-coded scheme — extend it only if a real naming collision shows up.

## 8 directions via 5 renders + runtime mirroring

Generate and normalize 5 unique directions per animation per layer: South,
South-diagonal, East, North-diagonal, North. East/West and the two diagonal pairs are
mirrors of each other — mirroring happens in Godot at runtime via `flip_h` (a future
milestone), not in this pipeline. This halves source-art and normalization work for a
symmetric humanoid. If a piece of gear is ever drawn asymmetrically (e.g. a sword fixed
to one hip), that direction needs its own non-mirrored render — call it out when it comes
up rather than assuming every layer can mirror.

## Folders

```text
assets/source/generated/<asset_id>/   raw AI source sheet(s), Godot-ignored
assets/manifests/<asset_id>.manifest.json
assets/sprites/<category>/<asset_id>.png
```

## Prompting tips (validated this session)

- Ask for a flat, uniform background at an exact hex color (`#ff00ff` magenta worked
  cleanly with ChatGPT in testing; Gemini's output was visibly washed out and added
  unrequested decoration — re-test before relying on a different tool).
- State the aspect ratio that matches the target cell (e.g. 2:3 for the 32x48 actor
  canvas) rather than literal pixel dimensions — these tools pick from their own native
  resolutions and ignore exact pixel requests, but generally respect aspect ratio.
- Add a line telling the model the art will be downscaled to a small game sprite — nudges
  it toward bold simple shapes over fine detail that would be lost anyway.
- For armor/equipment layers, edit the *same* base character image in-place in the same
  chat thread ("using the exact same character, pose, and framing... add X") rather than
  prompting a fresh image — both ChatGPT and Gemini held pose/proportions stable (a few
  pixels of drift) when editing in-place, which is what makes the `inherits` alignment
  check in this pipeline meaningful.
