# Eldoria-Godot Style Guide

This guide keeps visual work consistent while the project is still using placeholders.

## Visual direction

Eldoria should feel like a bright, readable, family-friendly top-down fantasy RPG.

Priorities:

- clear silhouettes
- readable sprites at small sizes
- warm village-fantasy tone
- simple shapes before detail
- strong contrast between player, NPCs, items, and ground

## Pixel-art rules

For early game-ready sprites:

- use transparent PNG backgrounds
- avoid blur and noisy edges
- keep outlines readable
- keep palettes limited
- avoid tiny details that disappear at 32x32

## Placeholder color language

Until final art arrives, use strong readable colors:

- Player: blue
- Elder Rowan: purple
- Mira the Gardener: green
- Golden star: yellow/gold
- Glowing herb: bright green
- Obstacles/wood: brown
- Floor/grass: green

## Character and NPC guidance

NPCs should be distinct even as placeholders:

- unique silhouette
- unique color
- unique position in village
- short readable name
- quest role reflected in color/shape

## Item guidance

Items should be visually distinct from the ground and NPCs.

- one clear central shape
- high contrast
- no tiny clutter
- readable at 16x16 or 32x32

## UI guidance

UI should stay simple and readable for children.

- large text
- short sentences
- strong contrast
- clear button labels
- avoid dense paragraphs in gameplay

Grade 2 text should be especially short and direct.

## Asset acceptance checklist

Before using an asset in a scene:

- [ ] file name uses `snake_case`
- [ ] transparent PNG unless intentionally otherwise
- [ ] correct target size
- [ ] readable in Godot at game scale
- [ ] source prompt or origin saved when applicable
- [ ] `.import` files committed if Godot generates them
