# Open Question Schema (`OQ-*`)

**Workflow**: all (specs / design / brainstorm)
**Session key**: `open_questions`
**Primary**: no (secondary/supporting across all workflows)

## Schema variants

### Specs / design variant

```yaml
OQ-001:
  state: "in_progress"  # ADR-0010: draft|in_progress|blocked|resolved|deferred
  created_round: {N}
  topic_id: "{topic}"   # agenda topic the question relates to
  title: "{title}"
  description: |
    {question or uncertainty}
  raised_by: "{participant-id}"
  blocking: {true|false}
  resolution: null      # Free text when state == "resolved"
```

### Brainstorm variant

```yaml
OQ-001:
  state: "in_progress"      # ADR-0010: draft|in_progress|blocked|resolved|deferred
  created_round: {N}
  disney_phase: "{dreamer|realist|critic}"   # Disney phase context (replaces topic_id)
  title: "{title}"
  description: |
    {question or uncertainty}
  raised_by: "{participant-id}"
  blocking: {true|false}
  resolution: null
```

## Field notes

- Difference between variants: specs/design use `topic_id` (agenda-based); brainstorm uses `disney_phase` (phase-machine-based). Choice driven by `PROFILE.progress.axis`.
- `blocking: true` indicates the question must be answered before the session can conclude (escalation candidate).
- `resolution` is `null` until the question is resolved; then it's a free-text resolution summary.
- Workflow-level note: `OQ-*` for brainstorm is documented in `session-schema.md`; for specs/design, the schema parallels OQ for brainstorm with `topic_id` swap.
