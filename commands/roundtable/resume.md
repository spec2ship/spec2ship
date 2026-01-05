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

# PHASE 1: LOAD SESSION

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Determine which session to resume

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

## Load session state

Read `.s2s/sessions/{session-id}.yaml` and extract:
- id, topic, workflow_type, strategy, status
- current_phase
- participants
- rounds[] (for state synthesis)

## Validate session integrity

**1. Schema validation:**

Check that required fields exist:
- `id` - session identifier
- `topic` - discussion topic
- `strategy` - facilitation strategy
- `current_phase` - active phase
- `participants` - list of participants
- `rounds` - rounds array

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

    Options:
    1. Continue with 'standard' strategy
    2. Archive session

**3. Participant validation:**

For each participant in session, verify agent file exists:
- `agents/roundtable/{participant-id}.md`

If any participant file missing:

    Warning: Participant agent files changed.

    Missing: {list}
    Available: {list}

    Options:
    1. Continue with available participants only
    2. Select replacement participants
    3. Archive session

## Validate session can be resumed

If session status is "completed":

    Session {session-id} is already completed.

    Topic: {topic}
    Outcome: {outcome.file}

    To start new discussion: /s2s:roundtable:start "topic"

If session status is "active" or "paused", proceed.

---

# PHASE 2: SYNTHESIZE STATE FROM ROUNDS

Calculate current state from rounds[] array (single source of truth):

## Calculate current consensus

```
current_consensus = []
for round in rounds:
    for item in round.consensus:
        if item not in current_consensus:
            current_consensus.append(item)
```

## Calculate open conflicts

```
introduced_conflicts = {}
resolved_conflict_ids = set()

for round in rounds:
    for conflict in round.conflicts:
        introduced_conflicts[conflict.id] = conflict
    for resolved in round.resolved:
        resolved_conflict_ids.add(resolved.conflict_id)

open_conflicts = [c for id, c in introduced_conflicts if id not in resolved_conflict_ids]
```

## Track conflict persistence

```
conflict_round_count = {}
for round in rounds:
    for conflict in round.conflicts:
        if conflict.id not in resolved:
            conflict_round_count[conflict.id] = conflict_round_count.get(conflict.id, 0) + 1
```

## Get previous synthesis

```
previous_synthesis = rounds[-1].synthesis if rounds else None
```

## Calculate rounds in current phase

```
rounds_in_phase = sum(1 for r in rounds if r.phase == current_phase)
```

---

# PHASE 3: DISPLAY CONTEXT

    Resuming Roundtable Session
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Status: {status}

    Progress:
    ─────────
    Phase: {current_phase}
    Total Rounds: {len(rounds)}
    Rounds in Phase: {rounds_in_phase}

    Consensus ({len(current_consensus)}):
    {for each item}
    ✓ {item}

    Open Conflicts ({len(open_conflicts)}):
    {for each conflict}
    ⚠ {conflict.description}
      {for each position}
      - {participant}: {position}

    Participants: {list}

    Continuing discussion...

---

# PHASE 4: UPDATE STATE

Update session file:
- Set `status: "active"`
- Update `paused_at: null`

Update `.s2s/state.yaml`:
- Set `current_session: "{session-id}"`

---

# PHASE 5: CONTINUE DISCUSSION LOOP

Use the same inline orchestration as start.md.

## Initialize loop state

- round_number = len(rounds)
- rounds_in_phase = (calculated above)
- max_rounds = config.roundtable.limits.max_rounds (default: 20)

## Resume round execution

Continue with the same loop as start.md:

For each round until conclusion or max_rounds:

### Step 1: Read current session state

(Already done in PHASE 2, but refresh after each round)

### Step 2: Generate question (Facilitator Task)

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator resuming a session.

Read your agent definition from: agents/roundtable/facilitator.md

=== SESSION STATE (RESUMED) ===
Topic: {topic}
Strategy: {strategy}
Current Phase: {current_phase}
Round: {round_number + 1}
Rounds in this phase: {rounds_in_phase}

=== HISTORY ===
Previous synthesis: {previous_synthesis}
Current consensus: {current_consensus}
Open conflicts: {open_conflicts with round counts}

=== ESCALATION CONFIG ===
max_rounds_per_conflict: {from config}
confidence_below: {from config}
critical_keywords: {from config}

=== CONTEXT ===
This is a RESUMED session. Focus on:
1. Resolving open conflicts
2. Building on existing consensus
3. Completing current phase goals

=== TASK ===
Generate the next question for this phase.

Return YAML:
```yaml
action: 'question'
question: '{the question}'
participants: 'all'
focus: '{focus area}'
```"
)
```

### Step 3: Collect participant responses (PARALLEL)

(Same as start.md - blind voting)

### Step 4: Synthesize responses (Facilitator Task)

(Same as start.md)

### Step 5: Update session file (Batch Write)

(Same as start.md)

### Step 6: Handle next action

(Same as start.md - continue, phase, conclude, escalate)

### Step 7: Check safety limits

(Same as start.md)

---

# PHASE 6: COMPLETION

When discussion concludes:

(Same as start.md - update session, generate output, display summary)

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Total Rounds: {total_rounds}

    Consensus Reached:
    {for each item}
    ✓ {item}

    {if open_conflicts}
    Unresolved (noted for follow-up):
    {for each conflict}
    ⚠ {description}

    Output: {outcome.file}

    Next steps:
      /s2s:roundtable:list   - View all sessions
      /s2s:plan              - Generate implementation plans
