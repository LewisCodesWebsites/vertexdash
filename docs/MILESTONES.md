# Milestones

## M1: One level, cube mode, exact physics

- Load one of your own levels from your Geometry Dash save.
- Draw blocks, spikes and the player as code-drawn shapes.
- Cube mode only, using deterministic fixed-step physics from SPEC.md (not Godot's physics engine).
- Death on spikes and block sides; restart on death.
- Done when: the same input timeline produces the same jump arcs and the same death or
  completion as the original, checked against recordings in SPEC.md section 6.

## M2: Real look and sound

- Load textures and music from the player's own install at runtime.
- Background, ground, colour channels.
- Music synced to the level start.

## M3: All game modes

- Ship, ball, UFO, wave, robot, spider, swing.
- Portals: mode, gravity, size, speed, mirror.
- Orbs and pads.

## M4: Things the original does not have

Ideas, to be decided:
- Physics debugger: hitboxes, velocity vectors, frame stepping, input timeline.
- Practice tools: rewind, slow motion, section looping.
- Editor improvements.