# Architecture Decision Schema (`ARCH-*`)

**Workflow**: design
**Session key**: `architecture_decisions`
**Primary**: yes (main output of design workflow)

```yaml
ARCH-001:
  state: "accepted"   # ADR-0010: draft|in_progress|accepted|rejected|deferred
  created_round: {N}
  topic_id: "{topic}"
  title: "{title}"
  context: |
    {context/problem statement that drives this decision}
  decision: |
    {the decision made — what was chosen}
  options:
    - name: "{option 1}"
      pros: ["{pro}"]
      cons: ["{con}"]
    - name: "{option 2}"
      pros: ["{pro}"]
      cons: ["{con}"]
    # ... typically 2-4 options evaluated
  rationale: |
    {why this option was chosen over the others}
  consequences:
    positive: ["{positive outcome}"]
    negative: ["{trade-off accepted}"]
  proposed_by: "facilitator"
  supported_by:
    - "{participant-id}"
  related_to: []
```

## Field notes

- Schema mirrors the MADR (Markdown Architecture Decision Records) format — see `madr-decisions` skill for export to standalone ADR files.
- `consequences.positive` and `consequences.negative` are both required arrays (consequences are always two-sided).
- `options` array MUST contain at least 2 entries (a decision implies a choice).
