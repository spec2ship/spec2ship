# Requirement Schema (`REQ-*`)

**Workflow**: specs
**Session key**: `requirements`
**Primary**: yes (main output of specs workflow)

```yaml
REQ-001:
  state: "approved"   # ADR-0010 lifecycle: draft|in_progress|approved|rejected|deferred
  created_round: {N}
  topic_id: "{topic}"   # agenda topic this requirement addresses
  title: "{title}"
  priority: "{must|should|could|wont}"   # MoSCoW
  description: |
    {full description of the requirement}
  acceptance:
    - "{acceptance criterion 1}"
    - "{acceptance criterion 2}"
  proposed_by: "facilitator"
  supported_by:
    - "{participant-id}"
  related_to: []      # Optional: related artifact IDs (REQ-*, BR-*, NFR-*, etc.)
```

## Field notes

- `priority` follows MoSCoW (Must / Should / Could / Won't have).
- `acceptance` is a non-empty array — each entry is a testable criterion.
- `description` uses YAML literal block scalar for multi-line text.
- `topic_id` references one of the workflow's agenda topic IDs (see `agenda-specs.md`).
