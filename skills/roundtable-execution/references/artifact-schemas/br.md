# Business Rule Schema (`BR-*`)

**Workflow**: specs
**Session key**: `business_rules`
**Primary**: yes

```yaml
BR-001:
  state: "approved"   # ADR-0010: draft|in_progress|approved|rejected|deferred
  created_round: {N}
  topic_id: "{topic}"
  title: "{title}"
  description: |
    {full description}
  conditions: |
    {when this rule applies}
  actions: |
    {what happens when conditions are met}
  related_to: []
```

## Field notes

- `conditions` and `actions` are both required text blocks, describing the rule's trigger and effect.
- Business rules are policy/process invariants, not technical requirements (those are `REQ-*` or `NFR-*`).
