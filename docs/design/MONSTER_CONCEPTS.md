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

## Elder Slime (first mini-boss, expansion backlog - placeholder art)

`scripts/enemies/ElderSlime.gd` (a small subclass of `MeadowSlime.gd`, reusing its whole
FSM/component architecture) / `scenes/enemies/ElderSlime.tscn`. A tougher variant of the
Meadow Slime rather than a new monster archetype, per NORTH_STAR's "cohesion over volume"
pillar: 6 hp (vs. 3), slower `move_speed` (30 vs. 40, so its one new move reads clearly), a
bigger guaranteed coin drop (3 vs. 1) and a higher bonus-coin chance (35% vs. 12%). Adds
exactly one new telegraphed move - a brief pause-and-flash windup, then a fast lunge at the
player's position - so a dangerous hit is always clearly cued before it lands (research:
`docs/design/RESEARCH_NOTES.md` §6.3). Currently placeholder art only: the same
`meadow_slime_idle.png` texture, scaled 1.5x and tinted a deep moss green (`Color(0.4, 0.55,
0.25)`) so it reads as visually distinct at a glance, per this doc's "placeholder-first"
precedent. Placed once, at a far corner of the M1 zone (position `(2350, 1450)`, under a new
`Bosses` sibling node in `Main.tscn` - deliberately NOT under the `Enemies` node `Spawner.gd`
watches, so the mini-boss does not respawn and stays a one-per-session encounter). A real
"elder"/aged slime art pass (e.g. a mossier, crowned variant) is a natural follow-up once
this system is proven live, using the same prompt shape as Meadow Slime's below with "an
older, larger, moss-covered version, with a small leaf or twig 'crown'" appended.

On death, the Elder Slime now also awards a one-time permanent **keepsake** ("Elder Slime's
Dewdrop", `GameState.award_keepsake("elder_slime_dewdrop")`) alongside its existing codex
entry — a text-only trophy shown in the character panel's "Keepsakes" section, giving the
fight a lasting, non-stat payoff (see the "Boss keepsake" expansion backlog slice).

## Bramble Boar (backup / variety for a later monster milestone)

Not yet implemented - a second enemy concept for when M2's roadmap calls for monster
variety (a later Phase 2 milestone, not M2 itself - see `docs/design/NORTH_STAR.md`'s
"resist feature equity" pillar; don't add this until there's a concrete reason to).

> A small, stout wild boar made of tangled brambles, vines, and packed dirt, for a bright
> family-friendly fantasy RPG - mischievous rather than scary, no tusks or gore. Flat
> uniform magenta (#ff00ff) background, bold simple shapes, single upper-left light source,
> will be downscaled to a small sprite. 2:3 aspect ratio.
