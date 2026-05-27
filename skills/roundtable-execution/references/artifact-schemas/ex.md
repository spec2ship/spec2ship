# Exclusion Schema (`EX-*`)

**Workflow**: specs
**Session key**: `exclusions`
**Primary**: no (secondary/supporting)

```yaml
EX-001:
  state: "approved"   # ADR-0010: draft|in_progress|approved|rejected|deferred
  created_round: {N}
  topic_id: "out-of-scope"   # typically the out-of-scope agenda topic
  title: "{title}"
  description: |
    {what is explicitly excluded from scope}
  rationale: |
    {why this is out of scope — cost, complexity, future phase, etc.}
  future_consideration: {true|false}
  related_to: []
```

## Field notes

- Exclusions are explicit "no" decisions, documented to prevent scope creep and to record the reasoning.
- `future_consideration: true` means "we might revisit in a future iteration"; `false` means "explicitly out of scope, not planned".
