# Zero_Delay



# 🚦 Traffic Signal FSM — Verilog Implementation

A fully synthesizable **4-way intersection traffic signal controller** implemented as a Finite State Machine (FSM) in Verilog, featuring emergency override modes, timer freeze/resume, and pedestrian ALL_RED phases.

---

## 📁 File Structure

```
traffic_fsm/
├── traffic_signal_fsm.v        # RTL Design — FSM module
├── traffic_signal_fsm_tb.v     # Testbench — 9 test cases
├── traffic_fsm_emergency.vcd   # Waveform dump (generated on simulation)
└── README.md                   # This file
```

---

## 🔢 Signal Encodings

| Signal  | Encoding (`[1:0]`) |
|---------|--------------------|
| RED     | `2'b00`            |
| GREEN   | `2'b01`            |
| YELLOW  | `2'b10`            |
| ALL_RED | `2'b11`            |

> `ALL_RED` is a special pedestrian crossing phase where **all four directions show red** simultaneously.

---

## 🗺️ FSM Block Diagram

```
                        ┌─────────────────────────────────────────────────────────┐
                        │                  TRAFFIC SIGNAL FSM                      │
                        │                                                           │
                        │   ┌──────────────────────────────────────────────────┐  │
                        │   │              EMERGENCY CONTROLLER                 │  │
                        │   │                                                   │  │
   emergency_force_red──┼──►│  Priority Resolver                               │  │
   emergency_green_north┼──►│  force_red > north > east > south > west         │  │
   emergency_green_east─┼──►│                                                   │  │
   emergency_green_south┼──►│  ┌───────────────┐   ┌─────────────────────┐    │  │
   emergency_green_west─┼──►│  │ State Snapshot│   │ Emergency Type Reg  │    │  │
                        │   │  │  stored_state │   │  emergency_type[2:0]│    │  │
         soft_reset─────┼──►│  │  stored_count │   │  0=force_red        │    │  │
                        │   │  └───────────────┘   │  1=north_green      │    │  │
                        │   │                       │  2=east_green       │    │  │
                        │   │                       │  3=south_green      │    │  │
                        │   │                       │  4=west_green       │    │  │
                        │   │                       └─────────────────────┘    │  │
                        │   └──────────────────────────┬───────────────────────┘  │
                        │                              │ emergency_mode            │
                        │                              ▼                           │
                        │   ┌──────────────────────────────────────────────────┐  │
                        │   │              NORMAL FSM (12 States)               │  │
                        │   │                                                   │  │
                        │   │  ┌──────────┐    ┌───────────┐    ┌──────────┐  │  │
                        │   │  │  NORTH   │───►│  NORTH    │───►│  NORTH   │  │  │
                        │   │  │  GREEN   │    │  YELLOW   │    │  RED     │  │  │
                        │   │  │ (20 clk) │    │ (5 clk)   │    │ (85 clk) │  │  │
                        │   │  └──────────┘    └───────────┘    └────┬─────┘  │  │
                        │   │       ▲                                 │        │  │
                        │   │       │                                 ▼        │  │
                        │   │  ┌────┴─────┐    ┌───────────┐    ┌──────────┐  │  │
                        │   │  │  WEST    │◄───│  WEST     │◄───│  EAST    │  │  │
                        │   │  │  RED     │    │  YELLOW   │    │  GREEN   │  │  │
                        │   │  │ (85 clk) │    │ (5 clk)   │    │ (20 clk) │  │  │
                        │   │  └──────────┘    └───────────┘    └────┬─────┘  │  │
                        │   │       ▲               ▲                 │        │  │
                        │   │       │               │                 ▼        │  │
                        │   │  ┌────┴─────┐    ┌───┴───────┐    ┌──────────┐  │  │
                        │   │  │  WEST    │    │  WEST     │    │  EAST    │  │  │
                        │   │  │  GREEN   │    │  RED      │    │  YELLOW  │  │  │
                        │   │  │ (20 clk) │    │ (85 clk)  │    │ (5 clk)  │  │  │
                        │   │  └──────────┘    └───────────┘    └────┬─────┘  │  │
                        │   │                                         │        │  │
                        │   │  ┌──────────┐    ┌───────────┐    ┌────▼─────┐  │  │
                        │   │  │  SOUTH   │◄───│  SOUTH    │◄───│  EAST    │  │  │
                        │   │  │  GREEN   │    │  YELLOW   │    │  RED     │  │  │
                        │   │  │ (20 clk) │    │ (5 clk)   │    │ (85 clk) │  │  │
                        │   │  └────┬─────┘    └───────────┘    └──────────┘  │  │
                        │   │       │                                           │  │
                        │   │       ▼                                           │  │
                        │   │  ┌──────────┐                                    │  │
                        │   │  │  SOUTH   │                                    │  │
                        │   │  │  YELLOW  │                                    │  │
                        │   │  │ (5 clk)  │                                    │  │
                        │   │  └────┬─────┘                                    │  │
                        │   │       │                                           │  │
                        │   │       ▼                                           │  │
                        │   │  ┌──────────┐                                    │  │
                        │   │  │  SOUTH   │                                    │  │
                        │   │  │  RED     │                                    │  │
                        │   │  │ (85 clk) │                                    │  │
                        │   │  └──────────┘                                    │  │
                        │   └──────────────────────────────────────────────────┘  │
                        │                                                           │
                        │   Outputs: north_light, east_light, south_light,         │
                        │            west_light [1:0], timer [6:0],                │
                        │            emergency_active                               │
                        └─────────────────────────────────────────────────────────┘
```

---

## 🔄 Normal FSM State Cycle

```
NORTH_GREEN (20) ──► NORTH_YELLOW (5) ──► NORTH_RED/ALL_RED (85)
                                                     │
                                                     ▼
WEST_RED/ALL_RED (85) ◄── WEST_YELLOW (5) ◄── EAST_GREEN (20)
       │                                             │
       ▼                                             ▼
WEST_GREEN (20)                              EAST_YELLOW (5)
       │                                             │
       ▼                                             ▼
WEST_YELLOW (5) ──► WEST_RED/ALL_RED (85)   EAST_RED/ALL_RED (85)
                                                     │
                                                     ▼
                              SOUTH_GREEN (20) ──► SOUTH_YELLOW (5)
                                                     │
                                                     ▼
                                           SOUTH_RED/ALL_RED (85)
                                                     │
                                                     └──────────────► (back to WEST_GREEN)
```

### Phase Durations

| Phase              | Duration (clock cycles) | Light State        |
|--------------------|-------------------------|--------------------|
| `*_GREEN`          | 20 cycles               | Direction = GREEN, rest = RED |
| `*_YELLOW`         | 5 cycles                | Direction = YELLOW, rest = RED |
| `*_RED` (ALL_RED)  | 85 cycles               | **ALL directions = ALL_RED** (pedestrian crossing) |

> **Total cycle per direction: 110 cycles** (20 + 5 + 85)

---

## 🚨 Emergency Mode Architecture

```
   Any Emergency Signal Asserted
              │
              ▼
   ┌─────────────────────────────┐
   │  Store current state/timer  │◄── current_state, count, count_next
   │  into snapshot registers    │
   └──────────────┬──────────────┘
                  │
                  ▼
   ┌─────────────────────────────┐
   │   Resolve Emergency Type    │
   │                             │
   │  force_red     → type = 0   │ ← HIGHEST PRIORITY
   │  green_north   → type = 1   │
   │  green_east    → type = 2   │
   │  green_south   → type = 3   │
   │  green_west    → type = 4   │ ← LOWEST PRIORITY
   └──────────────┬──────────────┘
                  │
                  ▼
   ┌─────────────────────────────┐
   │    Timer FROZEN             │
   │    FSM state FROZEN         │
   │    Output = emergency state │
   └──────────────┬──────────────┘
                  │
          soft_reset asserted
                  │
                  ▼
   ┌─────────────────────────────┐
   │  Restore stored state/timer │──► Normal FSM resumes
   │  emergency_mode = 0         │    from exact freeze point
   └─────────────────────────────┘
```

### Emergency Priority Table

| Priority | Signal                 | Effect                        |
|----------|------------------------|-------------------------------|
| 1 (High) | `emergency_force_red`  | ALL directions → ALL_RED, timer frozen |
| 2        | `emergency_green_north`| NORTH = GREEN, others = RED   |
| 3        | `emergency_green_east` | EAST = GREEN, others = RED    |
| 4        | `emergency_green_south`| SOUTH = GREEN, others = RED   |
| 5 (Low)  | `emergency_green_west` | WEST = GREEN, others = RED    |

---

## 📋 I/O Port Description

### Inputs

| Port                   | Width | Description                                      |
|------------------------|-------|--------------------------------------------------|
| `clk`                  | 1     | System clock                                     |
| `reset`                | 1     | Hard reset — resets FSM to NORTH_GREEN           |
| `emergency_force_red`  | 1     | Force ALL directions to ALL_RED + freeze timer   |
| `emergency_green_north`| 1     | Force NORTH GREEN (ambulance clearance)          |
| `emergency_green_east` | 1     | Force EAST GREEN                                 |
| `emergency_green_south`| 1     | Force SOUTH GREEN                                |
| `emergency_green_west` | 1     | Force WEST GREEN                                 |
| `soft_reset`           | 1     | Resume normal operation from stored state        |

### Outputs

| Port               | Width | Description                                      |
|--------------------|-------|--------------------------------------------------|
| `north_light`      | 2     | North signal: `00`=RED, `01`=GREEN, `10`=YELLOW, `11`=ALL_RED |
| `east_light`       | 2     | East signal (same encoding)                      |
| `west_light`       | 2     | West signal (same encoding)                      |
| `south_light`      | 2     | South signal (same encoding)                     |
| `timer`            | 7     | Current countdown value (0–127)                  |
| `emergency_active` | 1     | HIGH when emergency mode is active               |

---

## 🧪 Testbench — Test Cases

The testbench (`traffic_signal_fsm_tb.v`) includes **9 comprehensive test cases**:

---

### TEST 1 — Normal Operation Cycle

```
┌─────────────────────────────────────────────────────┐
│  Objective: Verify normal FSM cycling for 200 clocks │
│                                                       │
│  NORTH_GREEN → NORTH_YELLOW → NORTH_RED →            │
│  EAST_GREEN  → EAST_YELLOW  → EAST_RED  →            │
│  SOUTH_GREEN → ...                                    │
│                                                       │
│  Expected: Proper state transitions, timer counts     │
│  Pass Condition: Observed in waveform — no assertion  │
└─────────────────────────────────────────────────────┘
```

**What it checks:** FSM naturally cycles through all 12 states with correct timing.

---

### TEST 2 — Force ALL RED (Wrong-Way Ambulance)

```
┌─────────────────────────────────────────────────────┐
│  emergency_force_red = 1                             │
│                                                       │
│  Expected:                                            │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │ 2'b11│ 2'b11 │ 2'b11 │ 2'b11 │  ← ALL_RED       │
│  └──────┴───────┴───────┴───────┘                   │
│                                                       │
│  Timer: FROZEN (no decrement for 10 cycles)           │
│                                                       │
│  Then: emergency_force_red=0, soft_reset=1            │
│  → Resume from stored state                          │
└─────────────────────────────────────────────────────┘
```

**What it checks:** ALL_RED encoding (`2'b11`) on all lights, timer freeze, clean resume.

---

### TEST 3 — Force NORTH GREEN

```
┌─────────────────────────────────────────────────────┐
│  emergency_green_north = 1                           │
│                                                       │
│  Expected:                                            │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │ 2'b01│ 2'b00 │ 2'b00 │ 2'b00 │                  │
│  │GREEN │  RED  │  RED  │  RED  │                   │
│  └──────┴───────┴───────┴───────┘                   │
│                                                       │
│  Use case: Ambulance approaching from NORTH           │
│  Then soft_reset → resume                            │
└─────────────────────────────────────────────────────┘
```

---

### TEST 4 — Force EAST GREEN

```
┌─────────────────────────────────────────────────────┐
│  emergency_green_east = 1                            │
│                                                       │
│  Expected:                                            │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │ 2'b00│ 2'b01 │ 2'b00 │ 2'b00 │                  │
│  │ RED  │ GREEN │  RED  │  RED  │                   │
│  └──────┴───────┴───────┴───────┘                   │
└─────────────────────────────────────────────────────┘
```

---

### TEST 5 — Force SOUTH GREEN

```
┌─────────────────────────────────────────────────────┐
│  emergency_green_south = 1                           │
│                                                       │
│  Expected:                                            │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │ 2'b00│ 2'b00 │ 2'b01 │ 2'b00 │                  │
│  │ RED  │  RED  │ GREEN │  RED  │                   │
│  └──────┴───────┴───────┴───────┘                   │
└─────────────────────────────────────────────────────┘
```

---

### TEST 6 — Force WEST GREEN

```
┌─────────────────────────────────────────────────────┐
│  emergency_green_west = 1                            │
│                                                       │
│  Expected:                                            │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │ 2'b00│ 2'b00 │ 2'b00 │ 2'b01 │                  │
│  │ RED  │  RED  │  RED  │ GREEN │                   │
│  └──────┴───────┴───────┴───────┘                   │
└─────────────────────────────────────────────────────┘
```

---

### TEST 7 — Priority: `force_red` Overrides `green_north`

```
┌─────────────────────────────────────────────────────┐
│  Both asserted simultaneously:                       │
│    emergency_green_north = 1                         │
│    emergency_force_red   = 1  ← higher priority     │
│                                                       │
│  Priority Resolution:                                 │
│                                                       │
│  force_red ──────────────────────────────► WINS      │
│  green_north ── (ignored, lower priority)            │
│                                                       │
│  Expected:                                            │
│  All lights = 2'b11 (ALL_RED)                        │
│  NOT NORTH=GREEN                                     │
└─────────────────────────────────────────────────────┘
```

**What it checks:** The hardcoded priority chain `force_red > north > east > south > west`.

---

### TEST 8 — Priority Among Greens (`north > east`)

```
┌─────────────────────────────────────────────────────┐
│  Both asserted simultaneously:                       │
│    emergency_green_east  = 1                         │
│    emergency_green_north = 1  ← higher priority     │
│                                                       │
│  Expected: NORTH = GREEN  (not EAST)                 │
│                                                       │
│  Priority chain for green overrides:                 │
│  north (type=1) > east (type=2) > south > west       │
└─────────────────────────────────────────────────────┘
```

---

### TEST 9 — Hard Reset

```
┌─────────────────────────────────────────────────────┐
│  reset = 1 (held for 2 cycles), then reset = 0      │
│                                                       │
│  Expected state after reset:                         │
│  ┌──────┬───────┬───────┬───────┐                   │
│  │North │ East  │ South │ West  │                   │
│  ├──────┼───────┼───────┼───────┤                   │
│  │GREEN │  RED  │  RED  │  RED  │                   │
│  └──────┴───────┴───────┴───────┘                   │
│                                                       │
│  Also clears:                                        │
│  • emergency_mode → 0                                │
│  • stored_state → NORTH_GREEN                        │
│  • count → 0                                         │
│                                                       │
│  Difference from soft_reset:                         │
│  Hard reset = full state wipe                        │
│  Soft reset = resume from snapshot                   │
└─────────────────────────────────────────────────────┘
```

---

## 🏃 Simulation Instructions

### Using Icarus Verilog (iverilog)

```bash
# Compile
iverilog -o traffic_sim traffic_signal_fsm.v traffic_signal_fsm_tb.v

# Run simulation
vvp traffic_sim

# View waveform (requires GTKWave)
gtkwave traffic_fsm_emergency.vcd
```

### Using ModelSim / Questa

```tcl
vlog traffic_signal_fsm.v traffic_signal_fsm_tb.v
vsim traffic_signal_fsm_tb
run -all
```

### Expected Console Output

```
========== TESTBENCH START ==========
Normal operation begins (NORTH_GREEN)

[TEST 1] Normal cycle verified (observed in waveform)

[TEST 2] Force ALL RED + freeze timer
  ✓ ALL lights = ALL_RED
  Timer frozen at XX (no change observed)
  Soft reset -> resume normal cycle

[TEST 3] Force NORTH GREEN
  ✓ NORTH = GREEN, others RED

[TEST 4] Force EAST GREEN
  ✓ EAST = GREEN, others RED

[TEST 5] Force SOUTH GREEN
  ✓ SOUTH = GREEN, others RED

[TEST 6] Force WEST GREEN
  ✓ WEST = GREEN, others RED

[TEST 7] Priority: force_red > green
  ✓ force_red takes priority (ALL_RED)

[TEST 8] Priority among greens (North > East > South > West)
  ✓ North gets priority over East

[TEST 9] Hard reset -> back to NORTH_GREEN
  ✓ Hard reset: NORTH_GREEN

========== ALL TESTS PASSED ==========
Simulation complete. Open waveform to observe.
```

---

## ⚙️ Design Notes

### Timer Behavior

- `count` decrements every clock cycle during normal operation.
- When `count == 0`, the FSM transitions to the next state and loads `count_next`.
- During emergency mode, `count` is **not decremented** — the timer is fully frozen.
- On `soft_reset`, `stored_count` is restored, so the cycle resumes with exactly the remaining time.

### Combinational vs Sequential Logic

| Block         | Type          | Purpose                              |
|---------------|---------------|--------------------------------------|
| `always @(posedge clk)` | Sequential | State register, timer, emergency storage |
| `always @(*)`           | Combinational | Next-state logic, output decode      |

### Emergency Mode Entry/Exit

```
                 any_emergency asserted
                 while !emergency_mode
                        │
                        ▼
              ┌─────────────────────┐
              │  emergency_mode = 1  │
              │  snapshot taken      │
              └──────────┬──────────┘
                         │
              (stay here until soft_reset OR hard reset)
                         │
              soft_reset asserted     reset asserted
                    │                       │
                    ▼                       ▼
           Resume from snapshot     Full FSM reset
           emergency_mode = 0       to NORTH_GREEN
```

---

## 📌 Known Limitations / Future Work

- [ ] `soft_reset` de-asserted on the same clock edge it's applied — ensure single-cycle pulse from controller.
- [ ] Only one emergency can be active at a time (priority resolver picks one). Queuing multiple emergencies is not supported.
- [ ] Timer output is combinational (`timer = count`) — register it for glitch-free output in synthesis.
- [ ] Left-turn phases and pedestrian walk signals not implemented.
- [ ] Adaptive timing based on traffic density sensors not included.

---

## 📝 License

Open-source for academic and educational use.
