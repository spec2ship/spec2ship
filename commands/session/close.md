---
description: Close a session and mark it as completed. Works with any workflow type (specs, design, brainstorm, roundtable).
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, AskUserQuestion
argument-hint: [session-id]
---

# Close Session

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find session files: `.s2s/sessions/*.yaml`

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **session-id**: Optional. Specific session to close

### Find session to close

**IF** session-id provided in arguments:
- Verify session exists: `.s2s/sessions/{session-id}.yaml`
- If not exists, display error and list available sessions

**ELSE** find active sessions:

**Use Bash tool** to find all active sessions:

```bash
grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null
```

**IF** no active sessions found:

    No active sessions found.

    Use /s2s:session:list to see all sessions.

**IF** multiple active sessions found:

1. For each session, read and extract:
   - `id`
   - `workflow_type`
   - `topic`
   - `metrics.rounds_completed`

2. Display list:

```
Active sessions found:
══════════════════════

1. {session-id}
   Type: {workflow_type}
   Topic: {topic}
   Progress: {rounds_completed} rounds

2. {session-id}
   ...

Which session would you like to close?
```

3. Ask using AskUserQuestion with options for each session

**IF** single active session found:
- Use that session

### Read session file

Read `.s2s/sessions/{session-id}.yaml` and extract:
- `id`
- `workflow_type`
- `topic`
- `status`
- `timing.started`
- `metrics.rounds_completed`
- `metrics.artifacts.total`

### Confirm closure

Present summary and ask for confirmation using AskUserQuestion:

    Close Session
    ═════════════

    Session: {id}
    Type: {workflow_type}
    Topic: {topic}
    Started: {timing.started}
    Progress: {rounds_completed} rounds, {artifacts.total} artifacts

    Are you sure you want to close this session?

Options:
- "Yes, close session"
- "Cancel"

If user cancels, stop.

### Update session file

**Use Edit tool** to update `.s2s/sessions/{session-id}.yaml`:

1. Change `status: active` to `status: closed`
2. Add or update `timing.closed_at` with current ISO timestamp

```yaml
status: "closed"
timing:
  started_at: "{original}"
  updated_at: "{original}"
  closed_at: "{ISO timestamp}"
```

### Output

Display confirmation:

    Session closed!

    Session: {id}
    Type: {workflow_type}
    Topic: {topic}
    Duration: {calculated from started to closed_at}
    Artifacts: {artifacts.total}

    Session file: .s2s/sessions/{id}.yaml

    Commands:
    - View all sessions: /s2s:session:list
    - View session details: /s2s:session:status {id}
    - Clean up old sessions: /s2s:session:cleanup
