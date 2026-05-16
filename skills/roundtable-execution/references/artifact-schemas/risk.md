# Risk Schema (`RISK-*`)

**Workflow**: brainstorm
**Session key**: `risks`
**Primary**: yes (created in critic phase)

```yaml
RISK-001:
  state: "approved"         # ADR-0010 (brainstorm variant): draft|in_progress|approved|rejected
  created_round: {N}
  disney_phase: "critic"
  title: "{title}"
  description: |
    {what could go wrong}
  severity: "{high|medium|low}"
  likelihood: "{high|medium|low}"
  affected_ideas:
    - "{IDEA-NNN}"          # one or more IDEA-* IDs this risk impacts
  mitigation_id: null       # linked to MIT-* when a mitigation is proposed
  raised_by: "{participant-id}"
  related_to: []
```

## Field notes

- `disney_phase` is always `"critic"` for risks (only the critic phase identifies risks).
- `severity` × `likelihood` form a risk priority matrix (high/high = critical).
- `affected_ideas` MUST be a non-empty array — risks are tied to specific ideas.
- `mitigation_id` is `null` initially; set when a corresponding `MIT-*` is created.
