# VertexDash

An open-source, clean-room reimplementation of the Geometry Dash engine, built in Godot.

The goal is a faithful engine (same physics, same level format, same feel) that loads levels
and graphics from your own legally owned copy of Geometry Dash, plus features the original lacks.

## Status

Milestone 1 in progress. See [docs/MILESTONES.md](docs/MILESTONES.md).

## Requirements

- Godot 4.x
- Your own copy of Geometry Dash (Steam) for the real textures, music and levels.
  Without it, VertexDash falls back to built-in shapes drawn in code.

## Headless replay tests

Run the SPEC.md section 6 recording checks with:

```sh
godot --headless --path . --script res://scripts/test_runner.gd
```

The runner loads the hand-authored fixtures in `tests/levels/` and checks every recorded
position, death state, and annotated event tick. To play a saved level, pass the save path
and level name after `--`, for example:

```sh
godot --path . -- --gd-save="C:/path/to/CCLocalLevels.dat" --level="VDBlock"
```

Without `--level`, the game lists level names and exits. The default save path is
`%LOCALAPPDATA%/GeometryDash/CCLocalLevels.dat` on Windows.

## How this project is built

VertexDash follows a clean-room process. Behaviour is measured and written down in
[SPEC.md](SPEC.md) by one person or agent; the engine is written from that spec by another
who never sees the original game's code. See [docs/CLEANROOM.md](docs/CLEANROOM.md).

## Legal

VertexDash is not affiliated with or endorsed by RobTop Games. Geometry Dash is a trademark
of RobTop Games. This repository contains no code, art, music or other assets from
Geometry Dash. You must own the game to use its assets with VertexDash, and you should
support the original by buying it.

## License

MIT for VertexDash's own code. See [LICENSE](LICENSE).
