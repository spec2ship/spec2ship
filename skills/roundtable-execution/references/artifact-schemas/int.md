# Interface Schema (`INT-*`)

**Workflow**: design
**Session key**: `interfaces`
**Primary**: yes

```yaml
INT-001:
  state: "accepted"   # ADR-0010: draft|in_progress|accepted|rejected|deferred
  created_round: {N}
  topic_id: "{topic}"
  title: "{title}"
  type: "{REST|GraphQL|gRPC|message|file|event}"
  description: |
    {what this interface provides — endpoint description, message contract, etc.}
  endpoints:
    - path: "{path or topic}"
      method: "{GET|POST|publish|subscribe|etc.}"
      description: "{brief}"
    # ... or [] for non-endpoint-based interfaces
  related_to: []
```

## Field notes

- `type` constrains the kind of interface (HTTP-based, RPC, async messaging, file format, event stream).
- `endpoints` is an array, can be empty when not applicable (e.g., file format or one-off contract).
- Workflow-level note: `INT-*` is not yet documented in `session-schema.md` (predates Phase 7B; tracked as out-of-scope drift).
