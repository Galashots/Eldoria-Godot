# Research Notes

Five deep-research documents were produced by other AI tools (ChatGPT/Gemini/Codex deep
research) and reviewed critically when re-onboarding Claude to this project. They live in
the user's `~/Downloads`, not the repo. This file captures **what each is good for, what to
ignore, and why**, so the provenance and caveats aren't lost.

General caveat: all five are AI-generated "deep research." Treat them as well-sourced
starting points, not authority. Several cite plausible-but-unverified specifics (named
plugins, benchmark numbers, "Project Aeternum"). Verify before depending on a specific
claim.

## 1. Curriculum-Aligned Design Guide (PDF) — **the keeper**

*"Eldoria-V2 Design Guide for a Beautiful, Deep, Addictive, Immersive, Curriculum-Aligned
2D RPG."*

The most valuable and most Eldoria-specific. Evidence-based, with real sources (Sea of
Stars, Octopath II, CrossCode, Children of Morta; NN/g kids-UX; stealth-assessment
literature; Alberta curriculum).

- **Use:** the whole design spine — cohesive single vertical slice; quests as playable
  learning arcs; two age profiles (6–8 / 9–12); layered moment/session/meta loops;
  stealth/evidence-centered assessment; parental controls; accessibility defaults; ESRB
  E10+/COPPA safety. This drives `NORTH_STAR.md` and `CURRICULUM_MAP.md`.
- **Caveat:** subjects and exact Alberta outcome codes are intentionally unspecified — the
  user must pin them (tracked as `TODO` in `CURRICULUM_MAP.md`).

## 2. Claude — AI Coding in Godot (.docx) — **mine selectively**

*"AI-Powered Godot 2D RPG Development — A Reference Guide."* The strongest of the AI-coding
docs; modern and concrete.

- **Use:** the `CLAUDE.md` skeleton and GDScript conventions (typed vars, member ordering,
  snake_case files / PascalCase `class_name`, signals over polling); the asset
  normalization / palette-lock idea (Pyxelate); the "polish shader shortlist" (white-flash
  on hit, outline, dissolve, palette swap, water, chromatic aberration) for later.
- **Ignore for now:** its full data-driven architecture (EventBus + StateManager +
  SceneManager + RegistryManager + SaveManager, everything in `.tres`). That is heavier
  than this project wants — it conflicts with the deliberate one-autoload minimalism. Adopt
  pieces only when content justifies them.

## 3. Visual Design Guide V2 (PDF) — **cheap parts now, heavy parts later**

*"Executable 2D RPG Visual Design Guide for Eldoria V2."* A rigorous art/asset/animation
"production contract."

- **Use:** the cheap-to-lock technical decisions — 640×360, 16×16 grid, 32×48 actors,
  palette discipline, nearest import, naming, frame counts. Captured in `VISUAL_CONTRACT.md`.
- **Ignore for now:** atlas families, JSON metadata sidecars, asset/palette/animation
  registries, skeletal rigs — premature for a placeholder-polygon project.
- **Caveats:** it openly states it never saw the real Eldoria-V2 art style and *assumes*
  pixel-art/top-down; it is Unity-leaning (its only code sample is Unity C#). Useful rules,
  wrong default engine framing.

## 4. ChatGPT — AI Coding in Godot (.docx) — **low novelty**

*"AI-Assisted 2D RPG Game Development in Godot: A Comprehensive Guide."* A competent but
generic primer (version drift Godot 3 vs 4, prompt decomposition, signals/composition,
asset normalization).

- **Use:** fine as onboarding for someone new to AI-in-Godot.
- **Ignore:** nothing Eldoria-specific; mostly already practiced here.

## 5. Building a Family 2D RPG (PDF) — **process & safety**

*"Building a Family 2D RPG With Claude Code, OpenAI Codex, and Google AI Pro."*

- **Use:** multi-tool workflow (Claude as lead architect, Codex as parallel worker/reviewer,
  Gemini big-context reviewer); plan-mode-first habit; family-safety and licensing/release
  notes (CC0/commercial-only assets, itch.io, Google Play $25 fee, adult-operated 18+
  accounts). Relevant since the project is built across several AI tools.
- **Ignore:** engine debates (Godot already chosen) and overlap with docs #2/#4.

## Cross-cutting takeaway

Two camps: the AI-coding + visual guides push toward **more architecture and heavier
pipelines**; the curriculum guide and this project's own philosophy push toward **cohesion
and minimal scope**. Eldoria-Godot stays in the minimalist camp: let the curriculum guide
drive *what* to build, take only the cheap-to-lock technical decisions from the rest, and
defer heavyweight architecture/asset systems until real content demands them.
