# Disney Phase Machine

> **Status**: canonical reference (extracted from `brainstorm.md` Step 2.6d in TECH-002 Phase 7B.5).
> **Consumed by**: `phase-2-core.md` Step 2.10 (brainstorm workflow only — gated on `PROFILE.has_phase_transition == true`).
> **Strategy description**: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/disney.md`. This file is the algorithmic spec; the strategy doc is the human-facing description (mindsets, prompts, when-to-use).
> **Applies to**: `/s2s:brainstorm` workflow exclusively. Specs and design do not have phase transitions (`PROFILE.has_phase_transition == false`).

The Disney creativity method separates ideation into three sequential phases, each with a distinct mindset. The brainstorm roundtable encodes these phases as a state machine that advances when the facilitator returns `next: "phase"` from synthesis (Step 2.4).

---

## 1. Phase state machine

```
   ┌─────────┐   next:phase   ┌─────────┐   next:phase   ┌────────┐
   │ dreamer │──────────────▶│ realist │──────────────▶│ critic │──┐
   └─────────┘                └─────────┘                └────────┘  │
        ▲                          ▲                          │     │
        └── start (fresh session)  │                          │     │
                                   │                          │     │
                                   │              next:conclude (only valid here)
                                   │                          │     │
                                   │                          ▼     │
                                   │                       (exit Phase 2)
                                   └──────────────────────────────────┘
                                          (no backward transitions)
```

**Transition rules**:

| Current phase | `next` value from synthesis | Action |
|---------------|------------------------------|--------|
| `dreamer` | `continue` | Stay in dreamer; another round |
| `dreamer` | `phase` | Advance to `realist` |
| `dreamer` | `conclude` | **INVALID** — override to `phase` and warn |
| `realist` | `continue` | Stay in realist; another round |
| `realist` | `phase` | Advance to `critic` |
| `realist` | `conclude` | **INVALID** — override to `phase` and warn |
| `critic` | `continue` | Stay in critic; another round |
| `critic` | `phase` | **INVALID** — already in last phase; treat as `conclude` and warn |
| `critic` | `conclude` | Valid; exit Phase 2 loop, proceed to Phase 3 |
| any | `escalate` | Standard escalation handling (Step 2.9), no phase change |

> **Invariant**: `conclude` is only valid from the `critic` phase. Drift-handling: if the facilitator returns `conclude` from an earlier phase, the runtime overrides it to `phase` (advance), displays a warning, and continues. This prevents the algorithm from skipping phases.

---

## 2. Phase semantics

Each phase has a distinct mindset that participants follow. The mindset is conveyed via `disney_phase_rules` in the facilitator question input and via `disney_phase_instructions` in the participant input (see `phase-2-core.md` Steps 2.2 and 2.3).

### Dreamer phase
- **Mindset**: Generate ideas freely, no criticism, build on others' ideas.
- **Output**: `IDEA-*` artifacts in `state: "draft"`.
- **Typical duration**: 1-2 rounds (depending on topic breadth).
- **Transition signal**: facilitator detects sufficient idea volume / breadth → `next: "phase"`.

### Realist phase
- **Mindset**: Evaluate feasibility, suggest implementation paths, refine ideas.
- **Output**: `IDEA-*` artifacts gain `feasibility` and `implementation_notes` fields (state moves to `in_progress` or `promoted`).
- **Typical duration**: 1-2 rounds.
- **Transition signal**: facilitator detects sufficient feasibility coverage → `next: "phase"`.

### Critic phase
- **Mindset**: Identify risks and weaknesses, propose mitigations.
- **Output**: `RISK-*` and `MIT-*` artifacts.
- **Typical duration**: 1-2 rounds.
- **Transition signal**: facilitator detects sufficient risk/mitigation coverage → `next: "conclude"` (only valid terminal).

---

## 3. Session state representation

The Disney phase machine state lives in `session.yaml`:

```yaml
current_phase: "dreamer"        # or "realist" | "critic"
phases:
  - name: "dreamer"
    status: "active"            # active | completed | pending
    rounds: [1, 2]              # round numbers spent in this phase
  - name: "realist"
    status: "pending"
    rounds: []
  - name: "critic"
    status: "pending"
    rounds: []
```

**State updates per transition**:

When `next: "phase"` fires (Step 2.10):

1. Mark current phase: `phases[current].status = "completed"`.
2. Determine next phase from the machine (dreamer→realist, realist→critic).
3. Set `current_phase = "{next_phase}"`.
4. Mark next phase: `phases[next].status = "active"`.
5. Display: `[Phase Transition] {old_phase} → {new_phase}`.

When `next: "conclude"` fires from `critic`:

1. Mark critic phase: `phases[critic].status = "completed"`.
2. Leave `current_phase` as `"critic"` (the final phase is recorded).
3. Exit the Phase 2 loop; Step 2.9 dispatch proceeds to Phase 3.

---

## 4. Per-phase round_summary fields

Each round's `rounds[]` entry tags itself with the Disney phase that was active (via `PROFILE.round_summary.tag_field == "disney_phase"`):

```yaml
rounds:
  - round: 1
    timestamp: "..."
    disney_phase: "dreamer"
    facilitator_question: "..."
    # ...
```

Verbose dump filename pattern for brainstorm rounds includes the phase context implicitly via the round number (since phase machine is monotonic, round N → known phase via `phases[].rounds[]`). No filename change needed.

---

## 5. Edge cases

- **Resume mid-session**: `current_phase` is read from session.yaml at Phase 2 start. Resume is phase-aware — Step 2.2 input includes `disney_phase_rules.current_phase` derived from session state.
- **Min_rounds across phases**: `min_rounds` (from config) applies to the SUM of all phase rounds, not per-phase. If `min_rounds == 3` and dreamer ran 3 rounds, the session can `conclude` from critic in round 4 even if critic only had 1 round.
- **--interactive mode**: Step 2.8 offers "Continue / Skip to next phase / Exit" instead of plain "Continue / Conclude / Exit" (brainstorm-specific).

---

## 6. Implementation note for Step 2.10

`phase-2-core.md` Step 2.10 delegates to this document. The concrete actions per transition are:

```
IF PROFILE.has_phase_transition == false: SKIP Step 2.10.

IF synthesis next == "phase":
  Apply the transition rule from §1 table.
  Update session.yaml per §3.
  Display banner.

IF synthesis next == "conclude" AND session.current_phase != "critic":
  Override next = "phase" (apply transition).
  Display warning: "facilitator returned conclude from {current_phase}; advancing to next phase instead. conclude is only valid from critic."
```
