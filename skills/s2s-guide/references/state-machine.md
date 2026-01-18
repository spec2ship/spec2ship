# State Machines

State transitions in Spec2Ship.

## Session Lifecycle

```
┌─────────┐    ┌────────┐
│ active  │───▶│ closed │
└─────────┘    └────────┘
```

| From | To | Trigger |
|------|-----|---------|
| active | closed | All agenda items closed + min_rounds met |
| active | closed | rounds >= max_rounds |
| active | closed | User manually closes session |
| active | closed | Unrecoverable error |

---

## Artifact Lifecycle

### Standard Artifacts (REQ, BR, NFR, EX, ARCH, COMP, INT, IDEA, RISK, MIT)

```
┌────────┐
│ create │
└───┬────┘
    │
    ▼
┌────────┐
│ active │  (permanent)
└────────┘
```

Standard artifacts are **immutable** once created:
- `status`: always `active`
- `agreement`: `consensus` | `draft` | `conflict`

If a requirement needs refinement, create a **new artifact** with `related_to` referencing the original.

### Resolution Artifacts (OQ, CONF)

```
┌──────┐         ┌──────────┐
│ open │────────▶│ resolved │
└──────┘         └──────────┘
```

| From | To | Trigger |
|------|-----|---------|
| open | resolved | Question answered or conflict resolved |

Resolution tracking:
```yaml
resolved_conflicts:
  - conflict_id: "CONF-001"
    resolution: "Agreed on JWT approach"
    method: consensus  # consensus | facilitator | user_decision

resolved_questions:
  - question_id: "OQ-001"
    answer: "Use PostgreSQL for persistence"
```

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

| From | To | Trigger |
|------|-----|---------|
| open | partial | First coverage item addressed |
| partial | closed | All done_when criteria met |
| open | closed | All criteria met in single round |

**Closure Criteria**:
```yaml
done_when:
  criteria:
    - "Primary user personas identified"
    - "Entry/exit conditions defined"
  min_requirements: 2
```

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
└───────────────┘
```

---

## Next Action Decision

After synthesis, facilitator decides:

| Condition | Result |
|-----------|--------|
| rounds < min_rounds | `continue` (forced) |
| All agenda topics closed | `conclude` |
| rounds >= max_rounds | `conclude` (forced) |
| Low confidence + critical issue | `escalate` |
| Open conflicts remaining | `continue` |

### Escalation Triggers

- max_rounds_per_conflict exceeded
- Confidence below threshold on critical topic
- User explicitly requests

---

## Agent Resume State

| Agent Type | Default | Behavior |
|------------|---------|----------|
| Facilitator | resume | Continues with context |
| Participants | fresh | New agent each round |

When resuming, agent receives:
1. `context_reconciliation` block
2. Lists of artifacts_created, resolved_conflicts, resolved_questions
3. Instruction to treat current context as authoritative
