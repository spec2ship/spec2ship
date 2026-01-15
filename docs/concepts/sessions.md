# Sessions

Sessions are the persistent state of roundtable discussions. They track artifacts, decisions, and discussion history.

## Session Lifecycle

```
┌─────────┐   ┌─────────┐
│ active  │──▶│ closed  │
└─────────┘   └─────────┘
```

Sessions have only two states: `active` (in progress, can be resumed) and `closed` (finished).

## Session File

Each session is stored as a YAML file in `.s2s/sessions/`:

```yaml
# .s2s/sessions/20260111-specs-my-project.yaml
id: "20260111-specs-my-project"
workflow_type: "specs"
strategy: "consensus-driven"
status: "active"

timing:
  started_at: "2026-01-11T10:00:00Z"
  updated_at: "2026-01-11T11:30:00Z"

artifacts:
  requirements:
    REQ-001:
      status: active
      title: "User Authentication"
      priority: must
      description: |
        Users must be able to log in...
      acceptance:
        - Given valid credentials...
      proposed_by: product-manager
      supported_by: [qa-lead]

  open_questions:
    OQ-001:
      status: open
      question: "Which auth provider?"
      raised_by: technical-lead

rounds:
  - round: 1
    topic: "user-workflows"
    facilitator_question: |
      What are the primary user workflows?
    synthesis_summary: |
      Identified 3 key workflows...
    participant_positions:
      product-manager: "Focus on onboarding..."
      qa-lead: "Consider edge cases..."
    artifacts_created: [REQ-001, REQ-002]

metrics:
  rounds_completed: 3
  artifacts:
    total: 8
    by_type: {requirements: 5, open_questions: 3}
```

## Session Commands

| Command | Description |
|---------|-------------|
| `/s2s:session` | Show current session status |
| `/s2s:session:list` | List all sessions |
| `/s2s:session:status [id]` | Detailed session info |
| `/s2s:session:validate [id]` | Check session consistency |
| `/s2s:session:close [id]` | Close a session |
| `/s2s:session:cleanup` | Remove old sessions |

## Session Validation

Validate sessions for consistency:

```bash
# Structural validation (fast, deterministic)
/s2s:session:validate

# Deep validation (includes semantic checks)
/s2s:session:validate --level deep
```

**Structural checks**:
- Valid YAML structure
- Required fields present
- Valid artifact states
- Consistent references

**Deep checks** (LLM-based):
- Participant coherence
- Context integrity
- Quality assessment

## Resuming Sessions

Active sessions can be resumed:

```bash
# Resume an active session
/s2s:roundtable --session

# Or workflow commands auto-detect active sessions
/s2s:specs
```

The system maintains agent state for continuity:
- Facilitator remembers previous rounds
- Participants can be resumed with context
- Artifacts and positions are preserved

## Session ID Format

```
{YYYYMMDD}-{workflow}-{project-slug}

Examples:
- 20260111-specs-my-project
- 20260111-design-my-project
- 20260111-brainstorm-api-strategy
```

## Verbose Mode

Enable detailed session logging:

```bash
/s2s:specs --verbose
```

Creates additional files in session folder:
- Full participant responses
- Complete facilitator context
- Verification checklists

## Diagnostic Mode

Enable debugging:

```bash
/s2s:specs --diagnostic
```

Adds:
- Post-round analysis by session observer
- Anomaly detection
- Structured error reporting

---

*See also: [Roundtable](./roundtable.md) | [Configuration](../reference/configuration.md)*
