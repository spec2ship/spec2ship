---
description: List all sessions with their status, workflow type, and progress.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(grep:*), Read, Glob
argument-hint: [--status active|closed] [--type specs|design|brainstorm|roundtable]
---

# List Sessions

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find all `.s2s/sessions/*.yaml` files

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **--status**: Filter by session status (active|closed)
- **--type**: Filter by workflow type (specs|design|brainstorm|roundtable)

### Find sessions

Use Glob tool to find all session files:
```
.s2s/sessions/*.yaml
```

**IF** no session files found:

    No sessions found.

    Start a new session:
      /s2s:specs      - Requirements roundtable
      /s2s:design     - Design roundtable
      /s2s:brainstorm - Brainstorm session

### Read session files

For each session file found:

1. **YOU MUST use Read tool** to read the session file
2. Extract:
   - `id`
   - `topic`
   - `workflow_type`
   - `strategy`
   - `status`
   - `timing.started_at`
   - `timing.closed_at`
   - `metrics.rounds_completed`
   - `metrics.artifacts.total`

### Apply filters

**IF** --status provided:
- Only include sessions where `status` matches (active or closed)

**IF** --type provided:
- Only include sessions where `workflow_type` matches

### Format output

Group sessions by status:

    Sessions
    ═══════════════════════════════════════

    Active ({count})
    ─────────────────────────────────────
    {for each session where status == "active"}
    * {id}
      Type: {workflow_type} | Strategy: {strategy}
      Topic: {topic}
      Started: {timing.started_at}
      Progress: {metrics.rounds_completed} rounds, {metrics.artifacts.total} artifacts
    {/for}

    Closed ({count})
    ─────────────────────────────────────
    {for each session where status == "closed"}
    ✓ {id}
      Type: {workflow_type} | Strategy: {strategy}
      Topic: {topic}
      Duration: {calculated from started to closed_at}
      Result: {metrics.artifacts.total} artifacts
    {/for}

    ─────────────────────────────────────
    Total: {total count} sessions

    Commands:
    - Close a session: /s2s:session:close {id}
    - View session details: /s2s:session:status {id}
    - Clean up old sessions: /s2s:session:cleanup

---

## Status Icons

| Status | Icon |
|--------|------|
| active | * |
| closed | ✓ |
