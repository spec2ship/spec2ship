# Resume Capability Checks (RES-*)

Detailed definitions for resume capability tests. These verify that sessions can be correctly resumed from any interruption point.

---

## Critical Interruption Points

```
┌─────────────────────────────────────────────────────────────────────┐
│ ROUND N                                                              │
├──────────────────────────────────────────────────────────────────────┤
│ 1. BEFORE facilitator question                                       │
│    └── State: agent_state.facilitator.last_action = null/synthesis  │
│                                                                      │
│ 2. DURING facilitator question (agent running)                       │
│    └── State: agent spawned but no response yet                     │
│                                                                      │
│ 3. AFTER facilitator question, BEFORE participants                   │
│    └── State: facilitator returned, agent_state updated             │
│                                                                      │
│ 4. DURING participant responses (parallel execution)                 │
│    └── State: some participants responded, others pending           │
│                                                                      │
│ 5. AFTER participants, DURING synthesis                              │
│    └── State: all responses collected, synthesis running            │
│                                                                      │
│ 6. AFTER synthesis, DURING artifact processing                       │
│    └── State: synthesis returned, artifacts being written           │
│                                                                      │
│ 7. DURING session file update                                        │
│    └── Risk: file partially written, YAML corruption                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## RES-001: Facilitator agent_id Persistence

| Property | Value |
|----------|-------|
| **Severity** | critical |
| **Interruption Point** | After facilitator question |

### Purpose

Verify that facilitator agent_id is saved after question generation, enabling agent resume.

### Expected State

After facilitator question completes:

```yaml
agent_state:
  facilitator:
    agent_id: "abc123"      # NOT null
    last_round: N
    last_action: "question"
```

### Test Steps

1. Create or use test session with 1+ rounds
2. Read session file
3. Check `agent_state.facilitator.agent_id`
4. Verify it's not null after rounds_completed > 0

### Failure Indicates

- agent_state not being updated after facilitator Task
- Write happening before Task completion
- agent_id not being captured from Task result

### Evidence Schema

```yaml
check: RES-001
status: pass | fail
session_file: ".s2s-test/sessions/test-session.yaml"
evidence:
  rounds_completed: 2
  agent_state:
    facilitator:
      agent_id: "abc123"  # or null = FAIL
      last_round: 2
      last_action: "synthesis"
notes: "agent_id correctly persisted"
```

---

## RES-002: Participant agent_ids Persistence

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Interruption Point** | After participant responses |

### Purpose

Verify that participant agent_ids are saved, enabling participant resume.

### Expected State

After participants complete:

```yaml
agent_state:
  participants:
    product-manager:
      agent_id: "def456"
      last_round: N
    business-analyst:
      agent_id: "ghi789"
      last_round: N
    # ... all configured participants
```

### Test Steps

1. Read session file after round completion
2. Get configured participants list
3. For each participant, check agent_state.participants.{id}
4. Verify agent_id exists for each

### Failure Indicates

- Participant agent_state not being captured
- Partial updates (some participants missing)

### Evidence Schema

```yaml
check: RES-002
status: pass | fail
session_file: ".s2s-test/sessions/test-session.yaml"
evidence:
  configured_participants:
    - "product-manager"
    - "business-analyst"
    - "qa-lead"
  agent_state_participants:
    product-manager: "def456"
    business-analyst: "ghi789"
    qa-lead: null  # FAIL - missing
notes: "qa-lead agent_id not persisted"
```

---

## RES-003: last_round Tracking

| Property | Value |
|----------|-------|
| **Severity** | critical |
| **Interruption Point** | After each round |

### Purpose

Verify that `agent_state.facilitator.last_round` matches `metrics.rounds_completed`.

### Expected State

```yaml
agent_state:
  facilitator:
    last_round: 2        # Must equal...

metrics:
  rounds_completed: 2    # ...this value
```

### Test Steps

1. Read session file
2. Compare `agent_state.facilitator.last_round` with `metrics.rounds_completed`
3. They must be equal

### Failure Indicates

- last_round not updated after round completion
- Metrics updated but agent_state not (or vice versa)
- Resume will start from wrong round

### Evidence Schema

```yaml
check: RES-003
status: pass | fail
session_file: ".s2s-test/sessions/test-session.yaml"
evidence:
  agent_state_last_round: 1    # FAIL if different
  metrics_rounds_completed: 2
  match: false
notes: "Mismatch - resume will restart from round 1 instead of 2"
```

---

## RES-004: last_action Tracking

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Interruption Point** | After each step |

### Purpose

Verify that `last_action` correctly reflects the last completed step.

### Valid Values

| Value | Meaning |
|-------|---------|
| null | No action completed yet |
| "question" | Facilitator question completed |
| "synthesis" | Facilitator synthesis completed (round done) |

### Test Steps

1. Read session file
2. Check `agent_state.facilitator.last_action`
3. Correlate with session state:
   - After full round: should be "synthesis"
   - After question only: should be "question"

### Failure Indicates

- last_action not being updated
- Wrong value set

### Evidence Schema

```yaml
check: RES-004
status: pass | fail
session_file: ".s2s-test/sessions/test-session.yaml"
evidence:
  rounds_completed: 2
  last_action: "synthesis"  # Correct for completed round
  expected: "synthesis"
  match: true
```

---

## RES-005: Resume Parameter Usage

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Interruption Point** | On resume |

### Purpose

Verify that commands pass `resume` parameter correctly when agent_id exists.

### Expected Logic

```markdown
**IF** agent_state.facilitator.agent_id exists:
  **Use the roundtable-facilitator agent** with:
  - resume: true
  - agent_id: {existing agent_id}
**ELSE**:
  **Use the roundtable-facilitator agent** with:
  - resume: false (or omit)
```

### Test Steps

1. Analyze command instructions
2. Find facilitator Task invocation
3. Check for resume parameter logic
4. Verify agent_id is passed when resuming

### Failure Indicates

- Resume logic missing from command
- agent_id not passed to resumed agent

### Evidence Schema

```yaml
check: RES-005
status: pass | fail
command_analysis:
  specs.md:
    has_resume_check: true
    passes_agent_id: true
    line: 456
  roundtable.md:
    has_resume_check: false  # FAIL
    passes_agent_id: false
    notes: "Delegates to skill without explicit resume"
```

---

## RES-006: Delta Calculation

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Interruption Point** | On resume |

### Purpose

Verify that `updates_since_last_round` (delta) is computed correctly on resume.

### Expected Calculation

When resuming, facilitator should receive:
- Artifacts created since last facilitator round
- Questions resolved since last round
- Conflicts resolved since last round

### Test Steps

1. Create session with 2 rounds
2. Manually add artifacts to round 2
3. Simulate resume
4. Check that delta only includes round 2 items

### Failure Indicates

- Full artifact list sent instead of delta
- Empty delta when items exist
- Duplicate items in delta

### Evidence Schema

```yaml
check: RES-006
status: pass | fail
scenario:
  rounds_completed: 2
  artifacts_in_round_1: ["REQ-001", "REQ-002"]
  artifacts_in_round_2: ["REQ-003"]
expected_delta:
  artifacts_created: ["REQ-003"]
actual_delta:
  artifacts_created: ["REQ-001", "REQ-002", "REQ-003"]  # FAIL - includes old
notes: "Delta includes all artifacts, not just since last round"
```

---

## RES-007: Context Reconstruction

| Property | Value |
|----------|-------|
| **Severity** | critical |
| **Interruption Point** | On resume |

### Purpose

Verify that session_state passed to facilitator on resume is complete and accurate.

### Required Fields in session_state

```yaml
session_state:
  session_id: "..."
  topic: "..."
  workflow_type: "..."
  strategy: "..."
  current_round: N

  artifacts_summary:
    total: N
    by_type: {...}
    by_state: {...}

  agenda_status:
    - topic_id: "..."
      status: "open|partial|closed"

  open_conflicts: [...]
  open_questions: [...]

  updates_since_last_round:
    artifacts_created: [...]
    artifacts_transitioned: [...]
```

### Test Steps

1. Read session file
2. Construct expected session_state
3. Compare with what command would generate
4. Flag missing or incorrect fields

### Failure Indicates

- Incomplete context sent to facilitator
- Facilitator makes decisions without full information
- Resume produces inconsistent results

### Evidence Schema

```yaml
check: RES-007
status: pass | fail
session_file: ".s2s-test/sessions/test-session.yaml"
expected_fields:
  - session_id
  - topic
  - workflow_type
  - strategy
  - current_round
  - artifacts_summary
  - agenda_status
  - open_conflicts
  - open_questions
  - updates_since_last_round
actual_fields:
  - session_id
  - topic
  - workflow_type
  - strategy
  - current_round
  - artifacts_summary
  # Missing: agenda_status, open_conflicts, open_questions, updates_since_last_round
missing_fields:
  - agenda_status
  - open_conflicts
  - open_questions
  - updates_since_last_round
notes: "Critical context missing - facilitator will lack agenda awareness"
```
