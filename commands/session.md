---
description: Show current roundtable session status. Use subcommands for more options.
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Glob
argument-hint: (no arguments - shows current session)
---

# Session Status

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Bash: `grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null` to find active sessions

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Check for active sessions

Find active sessions using grep result from context.

**IF** no active sessions found:

    No active session.

    Recent sessions:
    {list last 3 sessions from .s2s/sessions/*.yaml}

    Commands:
      /s2s:session:list      - List all sessions
      /s2s:specs             - Start requirements roundtable
      /s2s:design            - Start design roundtable
      /s2s:brainstorm        - Start brainstorm session
      /s2s:roundtable        - Start generic roundtable

**IF** multiple active sessions found:
- List all active sessions with brief info
- Suggest: "Use `/s2s:session:status {id}` for details"

### Display active session

**IF** single active session found:

**YOU MUST use Read tool** to read the session file.

Display session summary:

    Current Session
    ═══════════════════════════════════════

    ID:       {id}
    Workflow: {workflow_type}
    Strategy: {strategy}
    Status:   {status}

    Started:  {timing.started_at}
    Duration: {calculated from timing}

    Progress
    ─────────────────────────────────────
    Rounds:   {metrics.rounds_completed}
    Artifacts: {metrics.artifacts.total}
      - Requirements: {metrics.artifacts.by_type.requirements}
      - Business Rules: {metrics.artifacts.by_type.business_rules}
      - NFR: {metrics.artifacts.by_type.nfr}
      - Open Questions: {metrics.artifacts.by_type.open_questions}
      - Conflicts: {metrics.artifacts.by_type.conflicts}

    Topics
    ─────────────────────────────────────
    {for each topic in agenda}
    [{status icon}] {topic_id}
    {/for}

    Status icons: ○ open | ◐ partial | ● closed

    Commands
    ─────────────────────────────────────
      /s2s:session:status    - Detailed view
      /s2s:session:validate  - Check consistency
      /s2s:session:close     - Close this session

---

## Status Icons

| Status | Icon |
|--------|------|
| open | ○ |
| partial | ◐ |
| closed | ● |
