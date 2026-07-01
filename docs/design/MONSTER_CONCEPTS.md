# Monster Concepts

Source-art prompts for monsters, ready to paste into ChatGPT once a monster's system is
proven live with placeholder art (same "bootstrap with a placeholder, then swap in real art"
order as `docs/design/VISUAL_CONTRACT.md`'s tileset precedent). Once approved, run the
result through `tools/asset_pipeline/` per `docs/art/ASSET_NORMALIZATION_PIPELINE.md`.

## Meadow Slime (M2 - first monster, real art landed)

`scripts/enemies/MeadowSlime.gd` / `scenes/enemies/MeadowSlime.tscn`. Deliberately the
lowest-stakes possible "first enemy" - slow, low hp, small contact damage, classic and safe
for a Grade 2/5 audience. Generated from the prompt below via ChatGPT, normalized through
`tools/asset_pipeline/` (`assets/manifests/meadow_slime_idle.manifest.json`, 32x32,
`center_bottom` anchor) into `assets/sprites/enemies/meadow_slime_idle.png` - a single
static idle pose, no directional facing (the slime doesn't turn to face the player).

> A cute, friendly-looking round slime monster for a bright, family-friendly fantasy RPG,
> made of translucent glowing green jelly with a simple happy/curious face, no teeth or
> menace, sitting on a patch of grass. Flat, uniform magenta (#ff00ff) background. Bold
> simple shapes, clean readable silhouette, single light source from the upper-left, since
> this will be downscaled to a small game sprite. 2:3 aspect ratio.

## Bramble Boar (backup / variety for a later monster milestone)

Not yet implemented - a second enemy concept for when M2's roadmap calls for monster
variety (a later Phase 2 milestone, not M2 itself - see `docs/design/NORTH_STAR.md`'s
"resist feature equity" pillar; don't add this until there's a concrete reason to).

> A small, stout wild boar made of tangled brambles, vines, and packed dirt, for a bright
> family-friendly fantasy RPG - mischievous rather than scary, no tusks or gore. Flat
> uniform magenta (#ff00ff) background, bold simple shapes, single upper-left light source,
> will be downscaled to a small sprite. 2:3 aspect ratio.
