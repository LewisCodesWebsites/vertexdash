# Clean-room process

VertexDash is built in two strictly separated roles.

## Analyst

- Uses Claude Code with REA, Geode mods (hitbox viewer, frame stepping) and screen recordings.
- Works in a private folder outside this repository (`vertexdash-analysis`). Raw evidence,
  decompiled output and notes stay there and are never committed here.
- Writes only measured behaviour into `SPEC.md`, following its rules.

## Builder

- Uses Codex (no REA registered).
- Reads only this repository: `SPEC.md`, the docs and the engine code.
- Never runs `rea`, never opens the analysis folder, never decompiles or disassembles the game.
- If something is missing or unclear in the spec, writes a question in `docs/SPEC_QUESTIONS.md`
  instead of guessing or investigating the game directly.

## Human (Lewis)

- Moves questions from the builder to the analyst and checks answers.
- Plays both versions side by side and decides when behaviour matches.
- Reviews every SPEC.md change before it is committed.

## Assets

The game's art, music and levels are never committed. The engine reads them at runtime from
the player's own install. Anything shipped in this repo is original or CC0.