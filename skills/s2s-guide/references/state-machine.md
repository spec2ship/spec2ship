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

## Artifact Lifecycle (ADR-0010)

All artifacts use a single `state` field with transitions tracked for audit.

### State Transition Diagram

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
┌───────┐    ┌─────────────────┐    ┌─────────────┐    ┌──────────┐
│ draft │───▶│ needs_discussion│───▶│ in_progress │───▶│ TERMINAL │
└───────┘    └─────────────────┘    └─────────────┘    └──────────┘
                                          │                  ▲
                                          ▼                  │
                                    ┌─────────┐              │
                                    │ blocked │──────────────┘
                                    └─────────┘

Side states (any → these):
    ┌──────────┐     ┌──────────┐
    │ deferred │     │ rejected │
    └──────────┘     └──────────┘
```

### Terminal States

| Artifact Types | Terminal States |
|----------------|-----------------|
| REQ, BR, NFR, EX | `approved`, `implemented` |
| ARCH, DEC, COMP, INT | `accepted` |
| IDEA | `promoted`, `parked` |
| OQ, CONF | `resolved` |

### Transition Conditions

| From | To | Trigger |
|------|-----|---------|
| draft | needs_discussion | Artifact ready for group discussion |
| needs_discussion | in_progress | Facilitator selects for current round |
| in_progress | *terminal* | Consensus reached (no blocks) |
| in_progress | blocked | At least one participant signals block |
| in_progress | deferred | Explicit decision to postpone |
| blocked | in_progress | Blocking concern addressed |
| *any* | rejected | Explicit decision to abandon |

### Audit Trail

State transitions are tracked in `rounds[].artifacts_transitioned`:

```yaml
artifacts_transitioned:
  - id: "REQ-001"
    from: "draft"
    to: "approved"
    reason: "consensus reached"
  - id: "CONF-001"
    from: "in_progress"
    to: "resolved"
    reason: "facilitator decision"
```

### Resolution Tracking

| Field | Structure | Description |
|-------|-----------|-------------|
| resolved_conflicts | `{conflict_id, resolution, method}` | How conflicts were resolved |
| resolved_questions | `{question_id, answer}` | How questions were answered |

Resolution methods: `consensus`, `facilitator`, `user_decision`

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
