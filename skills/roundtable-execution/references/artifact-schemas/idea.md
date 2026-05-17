# Idea Schema (`IDEA-*`)

**Workflow**: brainstorm
**Session key**: `ideas`
**Primary**: yes (main output of brainstorm dreamer/realist phases)

```yaml
IDEA-001:
  state: "draft"            # ADR-0010 (brainstorm variant): draft|in_progress|promoted|parked|rejected
  created_round: {N}
  disney_phase: "dreamer"   # which Disney phase generated this idea
  title: "{title}"
  description: |
    {description of the idea}
  potential_value: |
    {why this idea is valuable — what problem it solves or opportunity it captures}
  feasibility: null         # Added during realist phase: high|medium|low|unknown
  implementation_notes: null  # Added during realist phase: brief implementation sketch
  proposed_by: "{participant-id}"
  supported_by:
    - "{participant-id}"
  related_to: []
```

## Field notes

- `disney_phase`: usually `"dreamer"` (idea generation) but can also be `"realist"` if refined during feasibility analysis.
- `feasibility` and `implementation_notes` start `null` and are added by the realist phase. Critic phase may override `state` to `"parked"` or `"rejected"`.
- State `"promoted"` indicates the idea graduates to a formal artifact in a downstream specs/design session.
