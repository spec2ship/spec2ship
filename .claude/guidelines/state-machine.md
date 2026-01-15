# State Machines

This document defines all state transitions in Spec2Ship.

---

## Session Lifecycle

```
┌─────────┐    ┌────────┐
│ active  │───▶│ closed │
└─────────┘    └────────┘
```

Sessions have only two states:
- **active**: Session in progress, can be resumed
- **closed**: Session finished (successfully or not)

### Transitions

| From | To | Trigger |
|------|-----|---------|
| active | closed | All agenda items closed + min_rounds met |
| active | closed | rounds >= max_rounds |
| active | closed | User manually closes session |
| active | closed | Unrecoverable error |

---

## Artifact Lifecycle

### Standard Artifacts (REQ, BR, NFR, EX, IDEA, RISK, MIT, ARCH, COMP, INT)

```
     ┌────────┐
     │ create │
     └───┬────┘
         │
         ▼
     ┌────────┐
     │ active │ (immutable)
     └────────┘
```

Standard artifacts are **immutable** once created:
- **status**: Always `active`
- **agreement**: `consensus`, `draft`, or `conflict`

If refinement is needed, create a NEW artifact with updated content.

### Resolution Artifacts (OQ, CONF)

```
     ┌────────┐
     │ create │
     └───┬────┘
         │
         ▼
     ┌────────┐         ┌──────────┐
     │  open  │────────▶│ resolved │
     └────────┘         └──────────┘
```

| From | To | Trigger | Storage |
|------|-----|---------|---------|
| - | open | Artifact created | Initial state |
| open | resolved | Issue addressed | `resolution` field populated |

**Conflict Resolution Methods**:
- `consensus`: Participants agreed through discussion
- `facilitator`: Facilitator made judgment call
- `user_decision`: User intervened via escalation

---

## Topic Lifecycle

```
     ┌──────┐
     │ open │
     └──┬───┘
        │
        ▼
     ┌─────────┐
     │ partial │
     └────┬────┘
          │
          ▼
     ┌────────┐
     │ closed │
     └────────┘
```

### Transitions

| From | To | Trigger |
|------|-----|---------|
| open | partial | First coverage item addressed |
| partial | closed | All done_when criteria met |
| open | closed | All done_when criteria met in single round (rare) |

**Closure Criteria**:
```yaml
done_when:
  criteria:
    - "Primary user personas identified"
    - "Entry/exit conditions defined"
  min_requirements: 2
```

A topic is closed when:
1. All listed `criteria` appear in `coverage`
2. At least `min_requirements` artifacts created for that topic

---

## Round Lifecycle

```
     ┌───────────────┐
     │ facilitator   │
     │   question    │
     └───────┬───────┘
             │
             ▼
     ┌───────────────┐
     │  participant  │
     │   responses   │
     └───────┬───────┘
             │
             ▼
     ┌───────────────┐
     │ facilitator   │
     │   synthesis   │
     └───────┬───────┘
             │
             ▼
     ┌───────────────┐
     │ process       │
     │ artifacts     │
     └───────┬───────┘
             │
             ▼
     ┌───────────────┐
     │ update        │
     │ session file  │
     └───────┬───────┘
             │
             ▼
     ┌───────────────┐
     │ validate      │
     │ round output  │
     └───────────────┘
```

### Steps (from command perspective)

1. **Step 2.2**: Facilitator generates question + participant_context
2. **Step 2.3**: All participants respond (parallel)
3. **Step 2.4**: Facilitator synthesizes responses
4. **Step 2.5**: Process proposed artifacts
5. **Step 2.6**: Update session file
6. **Step 2.6b**: Validate round output

---

## Next Action Decision

```
                    ┌────────────────────┐
                    │ synthesis complete │
                    └─────────┬──────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
         ┌────────┐     ┌─────────┐     ┌──────────┐
         │continue│     │conclude │     │ escalate │
         └────────┘     └─────────┘     └──────────┘
```

### Decision Logic

| Condition | Result |
|-----------|--------|
| rounds < min_rounds | `continue` (forced) |
| All agenda topics closed | `conclude` |
| rounds >= max_rounds | `conclude` (forced) |
| Low confidence + critical issue | `escalate` |
| Open conflicts remaining | `continue` |

**Escalation Triggers**:
- max_rounds_per_conflict exceeded
- Confidence below threshold on critical keyword
- User explicitly requests

---

## Agent Resume State

```
                    ┌──────────────────┐
                    │ round completed  │
                    └────────┬─────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
         ┌──────────┐  ┌──────────┐  ┌──────────┐
         │ resume   │  │  fresh   │  │ dispose  │
         │(agent_id)│  │(new agent│  │(no track)│
         └──────────┘  └──────────┘  └──────────┘
```

### Resume Policy

| Agent Type | Default | Configurable |
|------------|---------|--------------|
| Facilitator | resume | Yes |
| Participants | fresh | Yes |

When resuming:
1. Agent receives context_reconciliation block
2. Lists artifacts_updated, artifacts_resolved
3. Instruction to treat current context as authoritative
