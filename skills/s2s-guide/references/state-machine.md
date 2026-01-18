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

```
     ┌────────┐
     │ create │
     └───┬────┘
         │
         ▼
     ┌────────┐
     │ active │◄───────────┐
     └───┬────┘            │
         │                 │
    ┌────┴────┬───────┐    │
    │         │       │    │
    ▼         ▼       ▼    │
┌───────┐┌──────────┐┌─────────┐
│amended││superseded││withdrawn│
└───┬───┘└──────────┘└─────────┘
    │ (revert)
    └──────────────────────┘
```

| From | To | Trigger |
|------|-----|---------|
| - | active | Artifact created |
| active | amended | Modification in later round |
| active | superseded | Replaced by new artifact |
| active | withdrawn | Removed from scope |
| amended | active | Revert to previous version |

**Rules**:
- `superseded` and `withdrawn` are terminal states
- `amended` preserves full history in amendments array

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
2. Lists of artifacts_updated, artifacts_resolved
3. Instruction to treat current context as authoritative
