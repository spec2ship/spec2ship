# Conflict Schema (`CONF-*`)

**Workflow**: all (specs / design / brainstorm)
**Session key**: `conflicts`
**Primary**: no (secondary/supporting across all workflows)

## Schema variants

### Specs / design variant

```yaml
CONF-001:
  state: "in_progress"  # ADR-0010: in_progress|blocked|resolved
  created_round: {N}
  topic_id: "{topic}"   # agenda topic the conflict relates to
  title: "{title}"
  positions:
    - participant: "{participant-id}"
      stance: "{position summary}"
      rationale: "{reason}"
    # ... at least 2 positions (a conflict implies disagreement)
  resolution: null      # Free text when state == "resolved"
```

### Brainstorm variant

```yaml
CONF-001:
  state: "in_progress"      # ADR-0010: in_progress|blocked|resolved
  created_round: {N}
  disney_phase: "{dreamer|realist|critic}"   # Disney phase context (replaces topic_id)
  title: "{title}"
  positions:
    - participant: "{participant-id}"
      stance: "{position summary}"
      rationale: "{reason}"
  resolution: null
```

## Field notes

- Same workflow tag pattern as `OQ-*`: specs/design use `topic_id`, brainstorm uses `disney_phase`.
- `positions` MUST contain at least 2 entries (a conflict requires opposing views).
- Lifecycle is simpler than other types: just `in_progress | blocked | resolved`.
- Workflow-level note: `CONF-*` for brainstorm is not yet documented in `session-schema.md` (tracked as out-of-scope drift).

## State transition: resolving a conflict

When the facilitator's synthesis includes a conflict in `resolved_conflicts[]`:

1. Edit the existing `CONF-NNN` entry in place:
   ```yaml
   CONF-001:
     state: "resolved"
     resolution: "{resolution summary from synthesis}"
   ```
2. Append to `rounds[].artifacts_transitioned` for audit:
   ```yaml
   artifacts_transitioned:
     - id: "CONF-001"
       from: "in_progress"
       to: "resolved"
       reason: "{resolution method}"
   ```
