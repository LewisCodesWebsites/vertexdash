# Test-case recordings

Measured runs of the original game for the test cases in [SPEC.md](../../SPEC.md) section 6.
Each run was frame-stepped one physics tick at a time, and the player state was read after every
step. They contain measured values only, and no game code or assets.

| File | Test case | Rows |
|------|-----------|------|
| `tc01_vdjump_single_jump.csv` | TC-01 | Every tick from 3 to 114 |
| `tc02_vdblock_jump_onto_block.csv` | TC-02 | Sampled ticks from 0 to 347; every tick around the jump, the block landing, the roll-off and the ground landing |
| `tc03_vdspike_death.csv` | TC-03 | Sampled ticks from 0 to 414; every tick from 410 up to the death |

Rows are not always consecutive. Missing ticks were stepped through but not read. With no input
the cube moves exactly as described in SPEC.md CUBE-01 and CUBE-02, so the missing values follow
from the rows on either side.

## Columns

| Column | Meaning |
|--------|---------|
| `tick` | Tick number n: the state after n physics steps from level start (SPEC.md SIM-01, 240 ticks/s). |
| `t_ms` | Level time in milliseconds as shown by the game (n × 4.1667, rounded to 2 decimals). |
| `x` | Player centre x in world units (SPEC.md SIM-02). |
| `y` | Player centre y in world units. 105 is resting on the ground. |
| `dead` | `true` on the tick the player died. |
| `event` | What happened on that tick: input, apex, landing, roll-off or death. Empty otherwise. |

The values were read from a 2-decimal on-screen display of position × 1000, so x and y are exact
to ±0.00001 units. An engine matches if every listed row agrees to within 0.001 units and every
event happens on the same tick.

Input ("jump tapped before tick n") means jump was pressed and released while the game was paused
between tick n−1 and tick n. No other input was given.

Recorded on Geometry Dash 2.2081 (Steam, Windows), normal speed, default cube.
