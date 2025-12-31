---
description: Resume a roundtable session. Continues from where the discussion left off.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [session-id]
---

# Resume Roundtable Session

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/state.yaml` to get `current_session` value
- Use Glob to list `.s2s/sessions/*.yaml`

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Determine which session to resume

Check $ARGUMENTS for session ID.

**If session ID provided**:
- Search for matching session file in `.s2s/sessions/`
- If exact match found, use it
- If partial match, confirm with user
- If no match, show available sessions and stop

**If no session ID provided**:
- If `current_session` exists in state.yaml, use it
- If no current session, show available sessions:

    No active session found.

    Available sessions:
    {list with status and details}

    Resume a specific session:
      /s2s:roundtable:resume <session-id>

    Or start a new discussion:
      /s2s:roundtable:start "topic"

### Load session state

Read the session file `.s2s/sessions/{session-id}.yaml` and extract:
- id
- topic
- workflow_type
- strategy
- status
- current_phase
- phases (with rounds)
- participants
- consensus (current)
- conflicts (current)
- config_snapshot

### Validate session can be resumed

If session status is "completed":

    Session {session-id} is already completed.

    Topic: {topic}
    Strategy: {strategy}
    Outcome: {outcome summary}
    Output: {path to generated document}

    To start a new discussion on related topic:
      /s2s:roundtable:start "new topic"

    To review the outcome:
      Read the output document at {path}

If session status is "paused" or "active", proceed with resume.

### Display session context

Show current state:

    Resuming Roundtable Session
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Status: {status}

    Progress:
    ─────────
    Current phase: {current_phase}
    Rounds in phase: {count}
    Total rounds: {total across phases}

    Consensus points: {count}
    {list if any}

    Open conflicts: {count}
    {list with positions if any}

    Participants: {list}

### Update session

Update the session file:
- Set `status` to "active"
- Add resume timestamp to metadata

Update `.s2s/state.yaml`:
- Set `current_session` to this session ID

### Prepare context for facilitator

Load all context needed:
1. Read `.s2s/CONTEXT.md` for project context
2. Read strategy skill from `skills/roundtable-strategies/references/{strategy}.md`
3. Compile full history from session file:
   - All phases completed
   - All rounds with responses
   - Current consensus and conflicts

### Resume discussion

Display resume message:

    Continuing discussion from Phase: {current_phase}, Round {round_number}...

Launch facilitator with full context:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator resuming a session.

Read agents/roundtable/facilitator.md

Session Input:
```yaml
session:
  id: \"{session-id}\"
  topic: \"{topic}\"
  workflow_type: \"{workflow-type}\"
  resumed: true

strategy:
  name: \"{strategy}\"
  current_phase: \"{current-phase}\"
  phases_remaining: [{remaining phases}]

participants:
  {participant list with roles}

history:
  phases_completed:
    {list of completed phases with summaries}
  current_phase_rounds:
    {list of rounds in current phase}
  rounds_completed: {total count}
  consensus:
    {full list of consensus points}
  conflicts:
    {full list of conflicts with positions}
  previous_synthesis: \"{last round synthesis}\"

context:
  project: \"{CONTEXT.md content}\"
```

You are resuming this discussion.
1. Briefly acknowledge where we left off
2. Continue from the current phase and round
3. Focus on resolving open conflicts
4. Drive toward consensus
5. Respond with structured YAML for next action"
)
```

### Continue with roundtable loop

After facilitator responds, continue with the same loop as in start.md:

1. Parse facilitator decision (generate_question or synthesize)
2. Execute participant Tasks based on decision
3. Call facilitator to synthesize
4. Batch write to session file
5. Check escalation triggers
6. Evaluate: continue, next phase, conclude, escalate

### Handle completion

Same as start.md - when facilitator returns `action: "conclude"`:

1. Generate appropriate output document
2. Update session file with outcome
3. Clear current_session from state.yaml
4. Display completion summary

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Phases: {phases completed}
    Total rounds: {count}

    Consensus Reached:
    {list}

    Output: {file path}
