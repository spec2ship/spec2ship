# Component Schema (`COMP-*`)

**Workflow**: design
**Session key**: `components`
**Primary**: yes

```yaml
COMP-001:
  state: "accepted"   # ADR-0010: draft|in_progress|accepted|rejected|deferred
  created_round: {N}
  topic_id: "{topic}"
  title: "{title}"
  responsibility: |
    {what this component does — single sentence ideally}
  interfaces:
    provides:
      - "{interface name or description}"
    requires:
      - "{interface required from other components}"
  dependencies:
    - "{external dependency or other COMP-* id}"
  technology: "{technology choice, e.g., 'Postgres 16', 'Node.js 22'}"
  related_to: []
```

## Field notes

- `responsibility` is the single-sentence summary (single responsibility principle).
- `interfaces.provides`/`requires` capture the component's public surface.
- `dependencies` can mix external dependencies (libraries, services) with internal references to other `COMP-*` IDs.
