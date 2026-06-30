# V2 to Godot Port Rules

Eldoria-V2 is read-only reference. Do not port it blindly.

Preserve its family-friendly tone, profile concept, educational quest idea, reward-first progression, readable UI, and playtest-first development. Rebuild systems in Godot-native form as small vertical slices.

Current non-goals are save/load, inventory depth, equipment, a curriculum bank, combat depth, procedural systems, and account, login, or cloud features.

"Equipment" here means gameplay/inventory mechanics (stats, an inventory UI, equip/unequip
systems) — still a non-goal. It does not cover the hero's visual armor layering ("paper
doll" sprite layers composited at runtime), which is an active art/presentation track; see
`docs/art/ASSET_NORMALIZATION_PIPELINE.md`. Adding visual armor layers is not license to
build the gameplay equipment system this rule defers.

