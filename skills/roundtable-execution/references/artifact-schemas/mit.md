# Mitigation Schema (`MIT-*`)

**Workflow**: brainstorm
**Session key**: `mitigations`
**Primary**: yes (paired with risks in critic phase)

```yaml
MIT-001:
  state: "approved"         # ADR-0010 (brainstorm variant): draft|in_progress|approved|rejected
  created_round: {N}
  disney_phase: "critic"
  title: "{title}"
  risk_id: "{RISK-NNN}"     # the RISK-* this mitigation addresses
  description: |
    {how to mitigate the risk — concrete action, control, or design choice}
  effort: "{high|medium|low}"        # implementation effort
  effectiveness: "{high|medium|low}" # how much this reduces the risk
  proposed_by: "{participant-id}"
  related_to: []
```

## Field notes

- `risk_id` MUST reference an existing `RISK-*` artifact. The corresponding RISK-*.mitigation_id should be updated to point back to this MIT-*.
- `disney_phase` is always `"critic"`.
- `effort` × `effectiveness` informs prioritization (high effectiveness / low effort = quick wins).
