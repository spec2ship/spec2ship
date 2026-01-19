# Edge Case Scenarios (EDGE-*)

Detailed definitions for edge case tests. These verify that commands handle unusual scenarios correctly.

---

## EDGE-001: Empty Session Resume

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Scenario** | Resume session with 0 rounds completed |

### Setup

1. Create session file manually or via interrupted init
2. Session has:
   - `status: "active"`
   - `rounds: []`
   - `metrics.rounds_completed: 0`
   - `agent_state.facilitator.agent_id: null`

### Expected Behavior

- Command detects active session
- Recognizes no rounds completed
- Starts from round 1 (not "resume")
- Does NOT try to resume non-existent agent

### Failure Modes

| Failure | Impact |
|---------|--------|
| Tries to resume null agent_id | Task error |
| Starts from round 0 | Invalid round number |
| Doesn't detect as active | Creates duplicate session |

### Test Steps

1. Create empty active session
2. Run `/s2s:specs` (or other workflow command)
3. Verify it starts round 1 correctly
4. Verify no resume-related errors

### Evidence Schema

```yaml
check: EDGE-001
status: pass | fail
scenario:
  session_file: ".s2s-test/sessions/empty-session.yaml"
  initial_state:
    status: "active"
    rounds_completed: 0
    agent_id: null
execution:
  detected_as_active: true
  started_round: 1
  resume_attempted: false
  errors: []
```

---

## EDGE-002: Mid-Round Resume

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Scenario** | Resume after facilitator question, before synthesis |

### Setup

1. Start session, let facilitator complete question
2. Interrupt before/during participant responses
3. Session has:
   - Facilitator question in verbose dump (if verbose)
   - `agent_state.facilitator.last_action: "question"`
   - Possibly partial participant responses

### Expected Behavior

Options (depends on implementation):
- **A**: Restart round from facilitator question
- **B**: Continue from where interrupted (resume participants)

Current implementation should clearly document which approach is used.

### Failure Modes

| Failure | Impact |
|---------|--------|
| Duplicate artifacts | Round creates same artifacts twice |
| Lost responses | Participant work discarded |
| Inconsistent state | last_action doesn't match actual state |

### Test Steps

1. Start session with --verbose
2. Interrupt after facilitator question completes
3. Resume session
4. Verify:
   - No duplicate artifacts
   - Round continues or restarts cleanly
   - State is consistent

### Evidence Schema

```yaml
check: EDGE-002
status: pass | fail
scenario:
  interrupt_point: "after facilitator question"
  facilitator_dump_exists: true
  participant_responses_partial: true
resume_behavior:
  approach: "restart round"  # or "continue"
  duplicate_artifacts: false
  state_consistent: true
```

---

## EDGE-003: Partial Participant Failure

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Scenario** | Some participants fail/timeout, others succeed |

### Setup

1. Configure 4 participants
2. Simulate 1-2 participant Tasks failing
3. Others complete successfully

### Expected Behavior

Per `error-handling.md`:
- Continue with remaining participants
- Note missing responses in synthesis prompt
- Do NOT block round completion

### Failure Modes

| Failure | Impact |
|---------|--------|
| Round fails entirely | All progress lost |
| Synthesis receives incomplete data | Poor synthesis quality |
| Missing participant not noted | Facilitator unaware |

### Test Steps

1. Configure test with known-failing participant (mock)
2. Run round
3. Verify:
   - Round completes
   - Synthesis mentions missing participant
   - Session file notes partial responses

### Evidence Schema

```yaml
check: EDGE-003
status: pass | fail
scenario:
  configured_participants: 4
  successful_participants: 3
  failed_participants: ["qa-lead"]
behavior:
  round_completed: true
  synthesis_notes_missing: true
  session_file_updated: true
  round_data:
    participant_positions:
      product-manager: "..."
      business-analyst: "..."
      ux-researcher: "..."
      # qa-lead missing
```

---

## EDGE-004: Max Rounds Reached

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Scenario** | Session reaches max_rounds limit |

### Setup

1. Set `max_rounds: 5` in config
2. Run session that doesn't conclude naturally
3. Reach round 5

### Expected Behavior

- Force conclude after round 5 completes
- Display clear message about limit reached
- Session status → "closed"
- Generate output despite incomplete discussion

### Failure Modes

| Failure | Impact |
|---------|--------|
| Continues beyond limit | Runaway session |
| Abrupt stop without output | Work lost |
| No indication of forced close | User confusion |

### Test Steps

1. Configure low max_rounds
2. Start session on complex topic
3. Run until limit
4. Verify:
   - Session closes at limit
   - Output generated
   - Message indicates forced conclusion

### Evidence Schema

```yaml
check: EDGE-004
status: pass | fail
scenario:
  max_rounds_config: 5
  rounds_completed: 5
behavior:
  forced_conclude: true
  conclusion_message: "Maximum rounds (5) reached. Concluding session."
  output_generated: true
  session_status: "closed"
```

---

## EDGE-005: Early Topic Closure

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Scenario** | All topics closed before min_rounds |

### Setup

1. Configure session with 2 topics
2. Both topics reach "closed" status in round 2
3. `min_rounds: 3`

### Expected Behavior

Options:
- **A**: Force continue until min_rounds (exploration questions)
- **B**: Allow early conclude (all goals met)

Current implementation should document which approach.

### Failure Modes

| Failure | Impact |
|---------|--------|
| Stuck in loop | No new questions to ask |
| Premature conclude | Minimum coverage not met |
| Inconsistent behavior | Sometimes early, sometimes not |

### Test Steps

1. Configure simple session (few topics)
2. Quickly achieve closure
3. Verify behavior at min_rounds boundary

### Evidence Schema

```yaml
check: EDGE-005
status: pass | fail
scenario:
  topics_count: 2
  all_closed_at_round: 2
  min_rounds: 3
behavior:
  early_conclude_allowed: true  # or false
  actual_rounds: 2  # or 3
  consistent_with_docs: true
```

---

## EDGE-006: Escalation Handling

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Scenario** | Conflict requires user decision |

### Setup

1. Create conflict that persists for `max_rounds_per_conflict` rounds
2. Trigger escalation condition

### Expected Behavior

1. Facilitator detects escalation trigger
2. Session pauses (if interactive) or notes escalation
3. User decision recorded
4. Session continues with decision applied

### Failure Modes

| Failure | Impact |
|---------|--------|
| Escalation not detected | Infinite conflict loop |
| Decision not recorded | Lost user input |
| Session doesn't continue | Blocked |

### Test Steps

1. Configure low `max_rounds_per_conflict: 2`
2. Create persistent conflict
3. Verify escalation triggers
4. Provide decision
5. Verify continuation

### Evidence Schema

```yaml
check: EDGE-006
status: pass | fail
scenario:
  conflict_id: "CONF-001"
  max_rounds_per_conflict: 2
  conflict_rounds: 2
behavior:
  escalation_triggered: true
  user_prompted: true
  decision_recorded: "Use approach A"
  session_continued: true
  conflict_resolved: true
```

---

## EDGE-007: YAML Special Characters

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Scenario** | Artifacts contain YAML special characters |

### Setup

Create artifacts with:
- Colons in text: `"Time: 10:30 AM"`
- Quotes: `"He said \"hello\""`
- Pipes: `"Option A | Option B"`
- Multiline: descriptions with newlines
- Unicode: emojis, non-ASCII

### Expected Behavior

- Session file remains valid YAML
- Content preserved exactly
- No parsing errors on read

### Failure Modes

| Failure | Impact |
|---------|--------|
| YAML syntax error | Session file corrupted |
| Content mangled | Information lost |
| Parsing fails | Session unreadable |

### Test Steps

1. Create session with special character content
2. Write to session file
3. Read back
4. Verify content matches

### Evidence Schema

```yaml
check: EDGE-007
status: pass | fail
test_content:
  with_colon: "Meeting time: 10:30 AM"
  with_quotes: "He said \"hello\""
  with_pipe: "Option A | Option B"
  multiline: |
    Line 1
    Line 2
  unicode: "Hello 👋 World"
results:
  yaml_valid: true
  content_preserved: true
  specific_issues: []
```
