---
description: Resume a roundtable session. Continues from where the discussion left off.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [session-id]
---

# Resume Roundtable Session

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/state.yaml` for `current_session`
- Use Glob to list `.s2s/sessions/*.yaml`

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Determine which session to resume

Check $ARGUMENTS for session ID.

**If session ID provided**:
- Search for matching session in `.s2s/sessions/`
- If exact match, use it
- If partial match, confirm with user
- If no match, show available sessions

**If no session ID provided**:
- If `current_session` in state.yaml, use it
- If no current session:

    No active session found.

    Available sessions:
    {list with status}

    Resume: /s2s:roundtable:resume <session-id>
    Or start new: /s2s:roundtable:start "topic"

### Load session state

Read `.s2s/sessions/{session-id}.yaml` and extract:
- id, topic, workflow_type, strategy, status
- current_phase, phases, participants
- consensus, conflicts
- config_snapshot

### Validate session integrity

Perform comprehensive validation:

**1. Schema validation:**

Check that required fields exist:
- `id` - session identifier
- `topic` - discussion topic
- `strategy` - facilitation strategy
- `current_phase` - active phase
- `participants` - list of participants
- `phases` - phase definitions

If any required field is missing:

    Error: Session file corrupted or incomplete.

    Missing fields: {list}

    Options:
    1. Archive and start new session
    2. Attempt manual recovery

**2. Strategy file validation:**

Check that strategy skill exists:
- `skills/roundtable-strategies/references/{strategy}.md`

If strategy file not found:

    Error: Strategy '{strategy}' not found.

    The strategy used in this session is no longer available.

    Options:
    1. Continue with 'standard' strategy
    2. Archive session

**3. Participant validation:**

For each participant in session, verify agent file exists:
- `agents/roundtable/{participant-id}.md`

If any participant file missing:

    Warning: Participant agent files changed.

    Missing: {list of missing participants}
    Available: {list of available agents}

    Options:
    1. Continue with available participants only
    2. Select replacement participants
    3. Archive session

**4. Config drift detection:**

Compare `config_snapshot` with current `.s2s/config.yaml`:

Check for differences in:
- Participants lists
- Escalation triggers
- Consensus thresholds

If significant differences detected:

    Config drift detected since session started:

    Participants:
      Session: {snapshot participants}
      Current: {current config participants}

    Escalation:
      Session: {snapshot triggers}
      Current: {current triggers}

    Options:
    1. Continue with original config (from session)
    2. Update session to use current config
    3. Review differences and decide

**5. History size warning:**

Count total rounds across all phases.

If total rounds > 20:

    Warning: Large session history ({count} rounds)

    This may impact performance and context quality.

    Options:
    1. Continue with full history
    2. Summarize early rounds (keep last 10 rounds detail)
    3. Archive and start fresh

### Validate session can be resumed

If session status is "completed":

    Session {session-id} is already completed.

    Topic: {topic}
    Outcome: {summary}
    Output: {path}

    To start new discussion: /s2s:roundtable:start "topic"

If session status is "active" or "paused", proceed.

### Display session context

    Resuming Roundtable Session
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Status: {status}

    Progress:
    ─────────
    Phase: {current_phase}
    Rounds: {count in phase} / {total}

    Consensus: {count}
    {list if any}

    Conflicts: {count}
    {list with positions}

    Participants: {list}

### Update session state

Update session file:
- Set `status: "active"`
- Add resume timestamp

Update `.s2s/state.yaml`:
- Set `current_session: "{session-id}"`

### Launch orchestrator

Resume discussion using orchestrator agent:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Orchestrator resuming a session.

Read your agent definition from: agents/roundtable/orchestrator.md

Session context (RESUMED):
```yaml
session:
  id: '{session-id}'
  topic: '{topic}'
  workflow_type: '{workflow-type}'
  strategy: '{strategy}'
  resumed: true

strategy_config:
  participation: '{from config_snapshot}'
  phases: {remaining phases}
  consensus:
    policy: '{from snapshot}'
    threshold: {from snapshot}

participants:
  {participant list}

current_state:
  phase: '{current phase}'
  rounds_completed: {count}
  consensus:
    {existing consensus points}
  conflicts:
    {existing conflicts}

history:
  phases_completed:
    {summaries of completed phases}
  last_synthesis: '{previous synthesis}'

context:
  project: '{CONTEXT.md content}'

max_rounds: {remaining rounds}
escalation_triggers: {from config}
```

You are RESUMING this discussion:
1. Review where the discussion left off
2. Continue from current phase and round
3. Focus on resolving open conflicts
4. Execute roundtable loop until conclusion

Return structured YAML with round data."
)
```

### Process results

Same as start.md:

1. Batch write round data to session file
2. Check status: round_complete, phase_complete, concluded, escalation_needed
3. Handle escalation if needed
4. Continue until conclusion

### Complete session

When orchestrator returns concluded:

1. Update session file with completion
2. Generate output document based on workflow_type
3. Clear current_session from state.yaml
4. Display completion summary

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Total rounds: {count}

    Consensus Reached:
    {list}

    Output: {file path}
