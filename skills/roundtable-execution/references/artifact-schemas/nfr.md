# Non-Functional Requirement Schema (`NFR-*`)

**Workflow**: specs
**Session key**: `nfr`
**Primary**: yes

```yaml
NFR-001:
  state: "approved"   # ADR-0010: draft|in_progress|approved|rejected|deferred
  created_round: {N}
  topic_id: "nfr-measurable"   # typically the dedicated NFR agenda topic
  title: "{title}"
  category: "{performance|security|usability|reliability|scalability|maintainability|portability|compatibility}"
  description: |
    {description}
  target: "{measurable target, e.g., 'p95 latency < 200ms'}"
  minimum: "{minimum acceptable value, e.g., 'p95 latency < 500ms'}"
  measurement: "{how to measure, e.g., 'application logs aggregated over 24h windows'}"
  related_to: []
```

## Field notes

- `category` follows ISO 25010 quality attributes (see `iso25010-requirements` skill).
- `target` is the ideal/aspirational value; `minimum` is the must-meet threshold.
- `measurement` specifies the method or instrument, not the value.
