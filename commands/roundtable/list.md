---
description: List all roundtable sessions with their status, strategy, and progress.
allowed-tools: Bash(ls:*), Read, Glob
argument-hint: [--status active|completed|all]
---

# List Roundtable Sessions

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find `.s2s/sessions/*.yaml`
- Read `.s2s/state.yaml` to get `current_session` value

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Check for sessions

If no session files found in `.s2s/sessions/`, display:

    No roundtable sessions found.

    Start a new discussion:
      /s2s:roundtable:start "topic"

    Examples:
      /s2s:roundtable:start "API versioning strategy"
      /s2s:roundtable:start "authentication architecture" --strategy debate

### Parse arguments

Check $ARGUMENTS for:
- **--status**: Filter by status
  - `active` - only active/paused sessions
  - `completed` - only completed sessions
  - `all` - all sessions (default)

### Read session files

For each session file found:
1. Read the YAML content
2. Extract:
   - **id**: Session identifier
   - **topic**: Discussion topic
   - **strategy**: Facilitation strategy used
   - **workflow_type**: specs/design/brainstorm
   - **status**: active/paused/completed
   - **started**: Start timestamp
   - **current_phase**: Current phase (for active)
   - **phases**: List of phases with round counts
   - **participants**: List of participants
   - **consensus**: Count of consensus points
   - **conflicts**: Count of open conflicts
   - **outcome**: Output file path (for completed)

### Calculate progress

For each session, calculate:
- Total rounds: sum of rounds across all phases
- Current phase name
- Round in current phase
- Phases completed / total phases

### Format output

Group sessions by status and display:

**Active sessions** (prefix with *):

```
* {session-id} (current)
  Topic: {topic}
  Strategy: {strategy}
  Started: {date}

  Progress:
  ├─ Phase: {current_phase} ({phase_index}/{total_phases})
  ├─ Round: {round_in_phase}
  ├─ Consensus: {count} points
  └─ Conflicts: {count} open

  Participants: {list}
```

**Paused sessions** (prefix with ⏸):

```
⏸ {session-id}
  Topic: {topic}
  Strategy: {strategy}
  Paused at: Phase {phase}, Round {round}
  Consensus: {count} | Conflicts: {count}
```

**Completed sessions** (prefix with ✓):

```
✓ {session-id}
  Topic: {topic}
  Strategy: {strategy}
  Completed: {date}
  Phases: {count} | Rounds: {total}
  Outcome: {output file path}
```

### Mark current session

If a session ID matches `current_session` from state.yaml, add "(current)" marker.

### Display summary

End with summary and commands:

    ════════════════════════════════════════
    Total: {n} sessions
    ├─ Active: {count}
    ├─ Paused: {count}
    └─ Completed: {count}

    Commands:
    ─────────
    Start new session:
      /s2s:roundtable:start "topic"

    Resume current session:
      /s2s:roundtable:resume

    Resume specific session:
      /s2s:roundtable:resume {session-id}

    Filter by status:
      /s2s:roundtable:list --status active
      /s2s:roundtable:list --status completed

### Strategy distribution (if multiple sessions)

If more than 3 sessions exist, show strategy usage:

    Strategy Usage:
    ├─ standard: {count} sessions
    ├─ disney: {count} sessions
    ├─ debate: {count} sessions
    └─ other: {count} sessions
