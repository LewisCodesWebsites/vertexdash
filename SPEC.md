# VertexDash behaviour specification

This file is the only source of truth for the builder. Every entry describes WHAT the
original game does, never HOW its code does it.

## Rules for entries

- No code, pseudocode, assembly, symbol names or addresses from the original game.
- Values are measured behaviour: numbers, units, timings, shapes, formats.
- Every entry has an ID, a value, how it was measured, and a confidence level.
- Confidence: `measured` (observed directly), `derived` (calculated from measurements),
  `community` (from public community documentation, with link), `unverified`.

Entry format:

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|

## 1. Simulation

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|
| SIM-01 | Physics tick rate | TBD | | |
| SIM-02 | Coordinate units and axis directions | TBD | | |

## 2. Cube mode

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|
| CUBE-01 | Horizontal speed at each speed setting | TBD | | |
| CUBE-02 | Gravity | TBD | | |
| CUBE-03 | Jump initial velocity | TBD | | |
| CUBE-04 | Jump height and duration | TBD | | |
| CUBE-05 | Jump buffering and hold-to-jump behaviour | TBD | | |
| CUBE-06 | Player hitbox size (outer and inner) | TBD | | |
| CUBE-07 | Rotation while airborne and snapping on landing | TBD | | |

## 3. Objects and collision

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|
| OBJ-01 | Block hitbox and landing rules | TBD | | |
| OBJ-02 | Spike hitbox | TBD | | |
| OBJ-03 | Death conditions | TBD | | |

## 4. Level format

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|
| LVL-01 | Where your own levels are stored on disk | TBD | | |
| LVL-02 | Level string encoding and compression | TBD | | |
| LVL-03 | Object record fields used by Milestone 1 | TBD | | |

## 5. Rendering and camera

| ID | Behaviour | Value | Measured how | Confidence |
|----|-----------|-------|--------------|------------|
| CAM-01 | Camera follow rules | TBD | | |

## 6. Test cases

Recorded runs the builder can replay to check the engine matches the original.

| ID | Level | Input timeline | Expected outcome | Recording |
|----|-------|----------------|------------------|-----------|