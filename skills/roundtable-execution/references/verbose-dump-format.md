# Verbose Dump File Format

When `--verbose` flag is set, write dump files to `rounds/` subfolder within the session folder.

## Naming Convention

```
{NNN}-{PP}-{actor}.yaml

NNN = 3-digit round number (001, 002, ...)
PP = 2-digit phase (01=question, 02=responses, 03=synthesis)
actor = facilitator, product-manager, etc.
```

**Examples**:
- `001-01-facilitator-question.yaml`
- `001-02-software-architect.yaml`
- `001-03-facilitator-synthesis.yaml`

## Dump File Content

```yaml
round: {N}
phase: {P}
actor: "{actor-id}"

timing:
  started_at: "{ISO timestamp}"
  completed_at: "{ISO timestamp}"
  duration_ms: {calculated}

tokens:
  input: {estimated}
  output: {estimated}

prompt: |
  {exact prompt sent}

response: |
  {exact response received}

result:
  valid: true
  warnings: []
  artifacts_created: [...]  # Only in synthesis
```

## Usage in Commands

Commands write dump files after each agent interaction:

| Step | File Pattern | Content |
|------|--------------|---------|
| 2.2 Facilitator Question | `{NNN}-01-facilitator-question.yaml` | Question decision |
| 2.3 Participant Response | `{NNN}-02-{participant-id}.yaml` | Position and rationale |
| 2.4 Facilitator Synthesis | `{NNN}-03-facilitator-synthesis.yaml` | Synthesis and next action |
