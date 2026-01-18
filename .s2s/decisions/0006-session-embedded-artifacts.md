# Session Embedded Artifacts

## Status

accepted

## Context and Problem Statement

Roundtable sessions produce artifacts (requirements, decisions, ideas) that need to be tracked and versioned. Should artifacts be separate files or embedded in the session file?

## Decision Drivers

- Simplicity: minimize file operations and sync requirements
- Self-sufficiency: session file should be complete without dependencies
- Auditability: enable debugging without requiring --verbose flag
- LLM-friendly: single file readable with one Read tool call
- Git-ignorable: `.s2s/` is in .gitignore - can't rely on git for recovery

## Considered Options

- Separate files per artifact
- Embedded artifacts in session file
- Event sourcing

## Decision Outcome

Chosen option: "Embedded artifacts in session file", because it provides a single source of truth with atomic updates.

```
.s2s/sessions/{id}.yaml    # Complete session with embedded artifacts
.s2s/sessions/{id}/rounds/ # Verbose dumps (optional, for debugging)
```

The session file contains:
- Session metadata
- All artifacts with full content
- Amendments inline within artifacts
- Round summaries for basic audit
- Metrics

### Consequences

- Good, because single file read provides complete context
- Good, because no sync issues between files
- Good, because participants receive inline context
- Good, because validation operates on one file
- Bad, because session file grows with artifacts (~50-100KB typical)
- Bad, because must update carefully to avoid corruption
- Neutral, because verbose dumps still available for deep debugging

## Pros and Cons of the Options

### Separate files per artifact

```
.s2s/sessions/{id}/
├── {id}.yaml         # Index only
├── REQ-001.yaml
├── REQ-002.yaml
└── rounds/           # Verbose dumps
```

- Good, because clean separation, small files
- Bad, because sync complexity between index and artifacts
- Bad, because multiple reads needed for full context
- Bad, because partial updates can leave inconsistent state

### Embedded artifacts

Single session file contains everything.

- Good, because single source of truth
- Good, because atomic updates
- Good, because one Read tool call for context
- Bad, because larger file size
- Neutral, because within reasonable limits for YAML

### Event sourcing

Store all changes as events, derive current state.

- Good, because complete audit trail
- Good, because any point-in-time reconstruction
- Bad, because complexity overkill for this use case
- Bad, because state derivation adds latency

## More Information

Session file schema (summary):

```yaml
id: "20260110-specs-myproject"
workflow_type: specs
strategy: standard
status: active

timing:
  started: "2026-01-10T14:30:00Z"
  last_activity: "2026-01-10T15:45:00Z"

artifacts:
  requirements:
    REQ-001:
      title: "User authentication"
      content: "..."
      amendments: [...]
    REQ-002:
      title: "..."

rounds:
  - round: 1
    topic: "core-requirements"
    synthesis_summary: "..."
    artifacts_created: ["REQ-001", "REQ-002"]

metrics:
  rounds_completed: 3
  artifacts:
    total: 5
    by_type: {requirements: 3, open_questions: 2}
```

Mitigations for negatives:
- Round summary provides basic audit without --verbose
- Verbose dumps remain available for deep debugging
- Validation commands detect inconsistencies
