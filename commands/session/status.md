---
description: Show detailed status of a specific session or the current session.
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Glob
argument-hint: [session-id]
---

# Session Status Detail

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

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

### Determine session ID

**IF** $ARGUMENTS contains a session ID:
- Use that ID

**ELSE** find active sessions:
- Use Bash: `grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null`
- **IF** no active sessions: Show error and list available sessions
- **IF** multiple active sessions: List them and ask user which to show using AskUserQuestion
- **IF** single active session: Use that session

### Read session file

**YOU MUST use Read tool** to read `.s2s/sessions/{session-id}.yaml`.

**IF** file doesn't exist:

    ⚠️ SESSION NOT FOUND
    Session '{session-id}' does not exist.

    Available sessions:
    {list from .s2s/sessions/*.yaml}

### Display detailed status

    Session Detail
    ═══════════════════════════════════════

    ID:        {id}
    Workflow:  {workflow_type}
    Strategy:  {strategy}
    Status:    {status}

    Timing
    ─────────────────────────────────────
    Started:      {timing.started_at}
    Last Activity: {timing.updated_at}
    Completed:    {timing.closed_at or "In progress"}
    Duration:     {calculated}

    Agent State
    ─────────────────────────────────────
    Facilitator: {agent_state.facilitator.agent_id or "Not resumed"}
      Last round: {agent_state.facilitator.last_round}

    Artifacts ({metrics.artifacts.total})
    ─────────────────────────────────────
    By Type:
      Requirements:    {count} ({list IDs})
      Business Rules:  {count} ({list IDs})
      NFR:             {count} ({list IDs})
      Exclusions:      {count} ({list IDs})
      Open Questions:  {count} ({list IDs})
      Conflicts:       {count} ({list IDs})

    By Status:
      Active:     {metrics.artifacts.by_status.active}
      Amended:    {metrics.artifacts.by_status.amended}
      Open:       {metrics.artifacts.by_status.open}
      Resolved:   {metrics.artifacts.by_status.resolved}

    Agenda ({metrics.topics.closed}/{metrics.topics.total} closed)
    ─────────────────────────────────────
    {for each topic in agenda}
    [{status_icon}] {topic_id}
        Coverage: {coverage items or "None yet"}
    {/for}

    Rounds ({metrics.rounds_completed})
    ─────────────────────────────────────
    {for each round in rounds}
    Round {round.round}: {round.topic_id}
      Question: {truncate round.facilitator_question to 80 chars}...
      Artifacts: {round.artifacts_created}
      Consensus: {round.consensus_reached}
      Next: {round.next_action}
    {/for}

    Validation
    ─────────────────────────────────────
    Last check: {validation.last_check or "Never"}
    Status:     {validation.status or "Not validated"}
    Warnings:   {validation.warnings count}

    Commands
    ─────────────────────────────────────
      /s2s:session:validate {id}  - Check consistency
      /s2s:session:close      - Continue discussion

---

## Status Icons

| Status | Icon |
|--------|------|
| open | ○ |
| partial | ◐ |
| closed | ● |
