# Instructions for coding agents (builder role)

You are the builder for VertexDash, a clean-room Geometry Dash engine in Godot 4.

Hard rules:
1. Build only from SPEC.md and the docs in this repository.
2. Never run `rea`, Ghidra, or any decompiler or disassembler. Never inspect Geometry Dash's
   executable or its code.
3. Never open or read `../vertexdash-analysis` or any folder outside this repository.
4. Never commit assets from Geometry Dash. Load them at runtime from a user-configured path.
5. If SPEC.md lacks something you need, add a question to docs/SPEC_QUESTIONS.md and stop
   that piece of work. Do not guess physics values.

Engineering rules:
- Physics is deterministic and fixed-step, implemented in our own code. Do not use Godot's
  physics bodies for player movement or collision.
- Simulation and rendering are separate: the simulation can run headless for tests.
- Every SPEC.md entry used in code is referenced by its ID in a comment, e.g. `# CUBE-02`.
- Test-case replays from SPEC.md section 6 must pass before a milestone is marked done.