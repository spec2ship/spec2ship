# Session Management Guide

Sessions track the state of roundtable discussions. This guide explains how to manage, resume, and validate sessions.

## Overview

Every roundtable discussion (specs, design, brainstorm) creates a session that persists its state.

### Commands

| Command | Description |
|---------|-------------|
| `/s2s:session` | Show current session status |
| `/s2s:session:list` | List all sessions |
| `/s2s:session:status [id]` | Detailed session info |
| `/s2s:session:validate [id]` | Check session consistency |
| `/s2s:session:close [id]` | Close a session |
| `/s2s:session:cleanup` | Remove old sessions |
| `/s2s:roundtable --session` | Resume an active session |

## Viewing Sessions

### Current Session

```bash
/s2s:session
```

Output:

```
Current Session: 20260111-specs-my-project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: active
Workflow: specs
Strategy: consensus-driven
Rounds: 3/20

Artifacts:
  Requirements: 5 (REQ-001 to REQ-005)
  Open Questions: 2 (OQ-001, OQ-002)

Updated: 10 minutes ago
```

### All Sessions

```bash
/s2s:session:list
```

Output:

```
Roundtable Sessions
━━━━━━━━━━━━━━━━━━━

Active:
  → 20260111-143000-specs-my-project
    Strategy: consensus-driven | Rounds: 3 | Artifacts: 7

Closed:
  ✓ 20260110-160000-design-my-project
    Strategy: debate | Rounds: 5 | Output: architecture/
  ✓ 20260109-120000-brainstorm-api
    Strategy: disney | Rounds: 5 | Output: summary.md
```

### Detailed Status

```bash
/s2s:session:status 20260111-143000-specs-my-project
```

Shows complete session details including:
- All artifacts with content
- Round-by-round summary
- Participant positions
- Metrics

## Session States

| State | Description | Can Resume? |
|-------|-------------|-------------|
| `active` | Currently in progress | Yes |
| `closed` | Finished (successfully or not) | No |

## Resuming Sessions

### Resuming an Active Session

```bash
/s2s:roundtable --session <session-id>
```

Or use auto-detect to resume the most recent active session:

```bash
/s2s:specs      # auto-detects active specs sessions
/s2s:design     # auto-detects active design sessions
/s2s:brainstorm # auto-detects active brainstorm sessions
```

### What's Preserved

When resuming, the session maintains:
- All artifacts created
- Round history
- Participant positions
- Agenda progress
- Strategy and phase

## Closing Sessions

Close a session when you're done with it:

```bash
/s2s:session:close
```

Or close a specific session:

```bash
/s2s:session:close <session-id>
```

Closing a session:
- Marks it as `closed`
- Adds a `closed_at` timestamp
- Prevents further resumption

## Session Validation

Validate sessions for consistency and completeness.

### Basic Validation

```bash
/s2s:session:validate
```

Runs structural checks:
- Valid YAML structure
- Required fields present
- Valid artifact states
- Consistent references

### Deep Validation

```bash
/s2s:session:validate --level deep
```

Adds semantic checks (LLM-based):
- Participant coherence
- Context integrity
- Quality assessment

### Validation Output

```
Session Validation: 20260111-143000-specs-my-project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Structural Checks:
  ✓ Valid YAML structure
  ✓ Required fields present
  ✓ Artifact states valid
  ✓ Round references consistent

Semantic Checks (--level deep):
  ✓ Participant contributions coherent
  ✓ Context propagation intact
  ⚠ Quality: REQ-003 acceptance criteria vague

Overall: VALID (1 warning)
```

## Session Cleanup

Remove old sessions:

```bash
/s2s:session:cleanup
```

### With Age Filter

```bash
/s2s:session:cleanup --older-than 7d
```

Removes sessions older than 7 days.

### What Gets Cleaned

- Closed sessions (output already generated)
- Sessions older than threshold

### What's Preserved

- Active sessions

## Session Files

Sessions are stored in `.s2s/sessions/`:

```
.s2s/sessions/
├── 20260111-143000-specs-my-project.yaml
├── 20260110-160000-design-my-project.yaml
└── 20260109-120000-brainstorm-api.yaml
```

### Session File Structure

```yaml
id: "20260111-143000-specs-my-project"
workflow_type: "specs"
strategy: "consensus-driven"
status: "active"

timing:
  started_at: "2026-01-11T14:30:00Z"
  updated_at: "2026-01-11T15:45:00Z"

config:
  participants: [product-manager, business-analyst, qa-lead]
  min_rounds: 3
  max_rounds: 20

artifacts:
  requirements:
    REQ-001:
      status: active
      title: "User Authentication"
      priority: must
      description: "Users must be able to log in..."
      proposed_by: product-manager
      supported_by: [qa-lead]

rounds:
  - round: 1
    topic: "user-personas"
    facilitator_question: "Who are the primary users?"
    synthesis_summary: "Identified 2 personas..."
    participant_positions:
      product-manager: "Focus on developers..."
      business-analyst: "Consider enterprise users..."
    artifacts_created: [REQ-001]

metrics:
  rounds_completed: 3
  artifacts:
    total: 7
    by_type: {requirements: 5, open_questions: 2}
```

## Verbose Mode

For debugging or auditing, use verbose mode:

```bash
/s2s:specs --verbose
```

Creates additional data in the session:
- Full participant responses
- Complete facilitator context
- Verification checklists

Verbose data is stored alongside the session.

## Diagnostic Mode

For troubleshooting:

```bash
/s2s:specs --diagnostic
```

Adds:
- Post-round analysis
- Anomaly detection
- Structured error reporting

## Best Practices

### Regular Validation

Run validation after completing important sessions:

```bash
/s2s:session:validate --level deep
```

### Cleanup Regularly

Prevent session buildup:

```bash
/s2s:session:cleanup --older-than 30d
```

### Use Verbose for Important Decisions

For decisions you might need to audit later:

```bash
/s2s:design --verbose
```

### Resume Rather Than Restart

If interrupted, always try to resume first:

```bash
/s2s:roundtable --session
```

Restarting loses all progress.

## Troubleshooting

### "Session not found"

Check if session exists:

```bash
/s2s:session:list
```

Session may have been cleaned up or closed.

### "Cannot resume closed session"

Closed sessions can't be resumed. Start a new session:

```bash
/s2s:specs  # or /s2s:design, /s2s:brainstorm
```

### Session seems corrupted

Run validation:

```bash
/s2s:session:validate <session-id>
```

If validation fails, you may need to start fresh.

### Too many sessions

Clean up old sessions:

```bash
/s2s:session:cleanup --older-than 7d
```

---

*See also: [Specs Workflow](./specs-workflow.md) | [Design Workflow](./design-workflow.md) | [Brainstorm Workflow](./brainstorm-workflow.md)*
