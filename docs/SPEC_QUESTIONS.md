# Open questions for the analyst

The builder adds questions here when SPEC.md is missing or unclear. The analyst answers by
updating SPEC.md and marking the question resolved.

| # | Question | Asked by | Status |
|---|----------|----------|--------|
| B-01 | CUBE-03 says a fresh press receives gravity on its first airborne tick (predicted delta +2.4669), while its recorded example and TC-01 section 6 say tick 9 moves +2.46690 from tick 8 y=105; however that delta follows from the stated jump velocity only if tick 9 moves +2.5155 and gravity starts on tick 10. Which behavior is authoritative? | Codex builder | Answered below |
| B-02 | M1 says to load one own level from the Geometry Dash save, and LVL-01–03 define file location, decoding and object fields, but no level selection, name matching, malformed-file behavior, or user-configured path UI is specified. What is the M1 selection/configuration behavior? | Codex builder | Answered below |
| B-03 | OBJ-03 says a death is followed by a restart from tick 0, while TC-03 explicitly says the next step restarts at tick 0. Must the next step report tick 0 only, or also advance the new attempt to tick 1? | Codex builder | Answered below |
| B-04 | CAM-01 is TBD, and M1 requests drawing the level and player. What camera behavior and rendering scale/view framing are expected for M1? | Codex builder | Answered below |
| B-05 | TC-01 and TC-02 describe a jump press and release before the departure tick, but CUBE-05 specifies hold-to-auto-rejump. Is a tap consumed as a one-tick buffered request, or does M1 require preserving held state across level ticks separately? | Codex builder | Answered below |
| B-06 | COL-02 says the cube uses the player's profile primary and secondary colors, but SPEC.md does not define where those colors are stored or their exact RGB values. Which profile source and color decoding should M2 use? | Codex builder | Answered below |
| B-07 | AST-06 says background parallax relative to the camera is unmeasured. What horizontal and vertical background scroll behavior should M2 reproduce? | Codex builder | Answered below |
| B-08 | MUS-01 says the music start offset relative to tick 0 is unmeasured. Should M2 start Stereo Madness at tick 0, or is there a measured offset to apply? | Codex builder | Answered below |
| B-09 | COL-02 allows object key `21` to select a non-default color channel, but section 7 only gives the default channel colors and does not specify decoding custom channel entries from the level header. Should M2 support custom level channels now, and what header/channel mapping should it use? | Codex builder | Answered below |

## Answers (reviewed by Lewis)

### B-01: Jump velocity on the first tick (no conflict)

CUBE-03 and TC-01 agree. Apply CUBE-02's order literally: on the departure tick of a fresh
press, set vertical velocity to 2.5155, then apply gravity for that tick (velocity becomes
2.4669), then move y by the new velocity. That gives tick 9 = 105 + 2.4669 = 107.46690.

The automatic re-jump while held (CUBE-05) is different and is measured: on its departure tick
the velocity is set to 2.5155 and y moves by the full +2.5155 with no gravity applied that tick;
gravity applies normally from the next tick. Implement both cases exactly as CUBE-03 states.

A reference simulation using this order reproduces every row of all three recordings within
0.0005 units.

### B-02: Level selection and save path (design decision)

Not part of the game's behaviour, so not a SPEC.md item. For M1:
- Save path: read from a setting, defaulting to `%LOCALAPPDATA%\GeometryDash\CCLocalLevels.dat`
  on Windows. Overridable with a command-line argument `--gd-save=<path>`.
- Level choice: command-line argument `--level=<name>`, matched against `k2` after trimming
  leading and trailing whitespace (so " VDBlock" matches "VDBlock"), case-insensitive. If no level
  is given, list the level names and exit.
- Malformed file, missing file or no matching level: print a clear error and exit; never crash,
  never write to the file (LVL-01).
- No in-game UI for this in M1.

Tests must not depend on the player's save file. Build the three test levels as fixtures in
`tests/levels/` from the object lists in SPEC.md section 6 (written by hand in the level-string
format of LVL-03), and have the test runner load those.

### B-03: What happens after a death

The tests end at the death tick, so M1 only has to report death on the correct tick. After a
death, the next step resets the attempt: the state becomes the tick-0 state (x = 0, y = 105,
on the ground). It does not also advance to tick 1. The visible restart delay in normal play is
unmeasured (OBJ-03); treat it as presentation only and do not model it in the simulation.

### B-04: Camera and framing (design decision)

CAM-01 stays TBD in the spec and is not needed for the headless tests. For the M1 prototype
scene: scale 30 world units to 60 px, keep the player at a fixed screen x about one third from
the left edge, keep the camera's y fixed so the ground sits near the bottom of the screen. The
analyst will measure the real camera for M2.

### B-05: Input model for taps and holds

Track two input facts between ticks: `pressed_since_last_tick` (latched when the button goes
down, cleared after each tick is computed) and `held` (current button state).
At the start of a tick, if the cube is on the ground or a block top and either flag is true,
it departs on this tick (CUBE-05). A tap entirely between two ticks sets only the latch, which
is enough. A press and release made entirely while airborne does nothing: clear the latch when
a tick ends with the cube in the air. While held, the cube spends exactly one tick on the
surface after each landing and then re-jumps (CUBE-05). Not specified yet: a press that starts in
the air and is still held at landing; for M1 treat it the same as held.

## Answers to B-06 to B-09 (reviewed by Lewis)

These are presentation choices for M2, not measured game behaviour. Each one is a single named
setting or constant with a comment saying it is a placeholder, so the analyst's measurements can
replace it later without touching anything else.

### B-06: Player icon colours

Reading the player's profile is not specified yet. For M2, make the colours project settings
`vertexdash/player/primary` and `vertexdash/player/secondary`, defaulting to the new-level player
channels in COL-01 (1005 = 125,255,0 and 1006 = 0,255,255). Draw the real cube from AST-02:
main layer tinted with the primary colour, secondary layer tinted with the secondary colour,
rotated as CUBE-07. Leave the glow layer out for now. Keep the code-drawn cube as the fallback.

### B-07: Background scrolling

Not measured yet. For M2, scroll the background horizontally at 0.1 times the camera's speed and
keep it fixed vertically, using a constant `BACKGROUND_PARALLAX := 0.1` marked as a placeholder.

### B-08: Music start

Not measured yet. Start the song exactly when the level starts (tick 0), with a constant
`MUSIC_OFFSET_SECONDS := 0.0` marked as a placeholder. Restart it from the beginning on every new
attempt.

### B-09: Custom colour channels

Not in M2. Only the default channels in COL-01 are used. An object whose key `21` names any other
channel is drawn with its normal sprite tinted with channel 1004 (white). Full colour-channel
support is a later milestone.