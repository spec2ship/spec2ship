# Session Resilience Verification Plan

**Created**: 2026-01-18
**Status**: draft
**Priority**: high
**Related**: TEST-001, QUAL-001

---

## Objective

Verify that all roundtable commands (specs, design, brainstorm, roundtable) can:
1. Resume a session interrupted at any point
2. Maintain state consistency throughout execution
3. Recover from partial failures gracefully
4. Produce deterministic, auditable outcomes

---

## Analysis Summary

### Command Architecture Differences

| Command | Lines | Architecture | Resume Implementation |
|---------|-------|--------------|----------------------|
| specs.md | ~1640 | Inline | Full agent_state + resume parameter |
| design.md | ~1600 | Inline | Full agent_state + resume parameter |
| brainstorm.md | ~1600 | Inline | Full agent_state + resume parameter |
| roundtable.md | ~360 | Delegates to skill | Minimal (no explicit resume in skill) |

**Key Finding**: `roundtable.md` delegates execution to `roundtable-execution` skill, but the skill has LESS resume detail than the inline commands.

### Critical Interruption Points

Per ogni round, ci sono 6 punti critici dove un'interruzione può avvenire:

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
│    └── Risk: question exists but no dump file (if verbose)          │
│                                                                      │
│ 4. DURING participant responses (parallel execution)                 │
│    └── State: some participants responded, others pending           │
│    └── Risk: partial participant_responses array                    │
│                                                                      │
│ 5. AFTER participants, DURING synthesis                              │
│    └── State: all responses collected, synthesis running            │
│                                                                      │
│ 6. AFTER synthesis, DURING artifact processing                       │
│    └── State: synthesis returned, artifacts being written           │
│    └── Risk: artifacts partially embedded in session file           │
│                                                                      │
│ 7. DURING session file update (rounds[], metrics, timing)            │
│    └── Risk: file partially written, YAML corruption                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Verification Categories

### Category 1: Structural Checks (STR-*)

Verifiche statiche sulla struttura dei file senza eseguire il workflow.

| ID | Check | Description | Files Involved |
|----|-------|-------------|----------------|
| STR-001 | Session file schema | Verify session file matches session-schema.md | session file |
| STR-002 | Snapshot files exist | Verify context-snapshot, config-snapshot, agenda.yaml | session folder |
| STR-003 | Artifacts consistency | artifacts.{type} keys match rounds[].artifacts_created | session file |
| STR-004 | Metrics accuracy | metrics.artifacts.total == sum of artifact maps | session file |
| STR-005 | Agenda status consistency | agenda[].status matches coverage evidence | session file |
| STR-006 | Agent state validity | agent_state.facilitator/participants have valid structure | session file |
| STR-007 | Round numbering | rounds[] has sequential numbers, no gaps | session file |
| STR-008 | Timing monotonicity | started_at < updated_at < closed_at (if present) | session file |
| STR-009 | Verbose dump completeness | If verbose, rounds/ has expected files per round | session folder |
| STR-010 | State field validity | All artifacts use valid state values per ADR-0010 | session file |

### Category 2: Resume Capability Checks (RES-*)

Verifiche sulla capacità di riprendere sessioni interrotte.

| ID | Check | Description | Test Method |
|----|-------|-------------|-------------|
| RES-001 | agent_id persistence | Facilitator agent_id saved after question | Verify in session file |
| RES-002 | participant agent_ids | All participant agent_ids saved after responses | Verify in session file |
| RES-003 | last_round tracking | agent_state.last_round matches rounds_completed | Compare values |
| RES-004 | last_action tracking | last_action correctly reflects question/synthesis | Verify logic |
| RES-005 | resume parameter usage | Commands pass resume=true and agent_id correctly | Instruction analysis |
| RES-006 | delta calculation | updates_since_last_round computed correctly | Instruction analysis |
| RES-007 | context reconstruction | session_state passed to facilitator is complete | Compare with session file |

### Category 3: State Transition Checks (TRANS-*)

Verifiche sulle transizioni di stato degli artefatti.

| ID | Check | Description | Method |
|----|-------|-------------|--------|
| TRANS-001 | Valid transitions | All state transitions follow ADR-0010 rules | Compare from/to |
| TRANS-002 | Audit trail | artifacts_transitioned logged in rounds[] | Verify presence |
| TRANS-003 | No orphan states | Every artifact has a documented creation round | Check created_round |
| TRANS-004 | Terminal state finality | Approved/resolved artifacts not modified | Historical check |
| TRANS-005 | Conflict resolution tracking | resolved_conflicts has resolution method | Check method field |

### Category 4: Context Propagation Checks (CTX-*)

Verifiche sulla propagazione del contesto ai participant.

| ID | Check | Description | Method |
|----|-------|-------------|--------|
| CTX-001 | participant_context completeness | shared section has all required fields | Check structure |
| CTX-002 | artifact content propagation | relevant_artifacts have full content, not just IDs | Verify all fields |
| CTX-003 | recent_rounds propagation | Last 2-3 rounds included with full synthesis | Check length/content |
| CTX-004 | overrides strategy-aware | Debate/six-hats have appropriate overrides | Check per strategy |
| CTX-005 | workspace context | Component sessions include workspace context | Verify @ references |

### Category 5: Command Consistency Checks (CONS-*)

Verifiche sulla consistenza tra i 4 command.

| ID | Check | Description | Method |
|----|-------|-------------|--------|
| CONS-001 | Session ID format | Same format across commands | Pattern match |
| CONS-002 | Snapshot file structure | Same fields in context-snapshot.yaml | Compare schemas |
| CONS-003 | Resume logic equivalence | Same agent_state handling | Instruction diff |
| CONS-004 | Verbose dump format | Same naming/structure | Compare files |
| CONS-005 | Error handling | Same patterns for failures | Instruction analysis |
| CONS-006 | Diagnostic mode | Same observer integration | Compare --diagnostic |

### Category 6: Instruction Quality Checks (INST-*)

Verifiche sulla qualità delle istruzioni per LLM.

| ID | Check | Description | Method |
|----|-------|-------------|--------|
| INST-001 | Imperative voice | Instructions use imperative voice | Text analysis |
| INST-002 | Tool usage explicit | "YOU MUST use X tool NOW" patterns | Pattern search |
| INST-003 | No ambiguity | Steps have clear success/failure criteria | Human review |
| INST-004 | Template/inline alignment | Generated content matches templates | Diff analysis |
| INST-005 | Config reference | Values from config, no hardcoded defaults | Pattern search |
| INST-006 | ADR compliance | State field usage per ADR-0010 | Term search |

### Category 7: Edge Case Checks (EDGE-*)

Verifiche su casi limite e scenari anomali.

| ID | Check | Description | Method |
|----|-------|-------------|--------|
| EDGE-001 | Empty session resume | Resume with 0 rounds completed | Scenario test |
| EDGE-002 | Mid-round resume | Resume after facilitator question, before synthesis | Scenario test |
| EDGE-003 | Partial responses | Some participants failed, others succeeded | Scenario test |
| EDGE-004 | Max rounds reached | Behavior when max_rounds limit hit | Scenario test |
| EDGE-005 | All topics closed early | Conclude before min_rounds | Scenario test |
| EDGE-006 | Escalation handling | User decision recorded correctly | Scenario test |
| EDGE-007 | YAML special chars | Artifacts with quotes, colons, pipes | Content test |

---

## Implementation Plan

### Phase 1: Create Structural Validator Agent

**File**: `.claude/agents/s2s-session-validator.md`

```yaml
name: s2s-session-validator
description: "Validates session file structure and consistency. Run after each round or at resume."
model: haiku  # Fast, low-cost for structural checks
tools: ["Read", "Glob"]
```

**Capabilities**:
- Run STR-* checks on demand
- Return structured report with pass/fail/warning
- Suggest fixes for common issues

### Phase 2: Create Resume Tester Agent

**File**: `.claude/agents/s2s-resume-tester.md`

```yaml
name: s2s-resume-tester
description: "Tests resume capability by analyzing session state at various interruption points."
model: sonnet  # Needs reasoning for complex state analysis
tools: ["Read", "Glob"]
```

**Capabilities**:
- Analyze session file and determine resume point
- Verify agent_state is complete for resume
- Simulate what would happen on resume

### Phase 3: Create Instruction Analyzer Agent

**File**: `.claude/agents/s2s-instruction-analyzer.md`

```yaml
name: s2s-instruction-analyzer
description: "Analyzes command/agent instructions for quality, consistency, and compliance."
model: sonnet
tools: ["Read", "Glob", "Grep"]
```

**Capabilities**:
- Run INST-* checks
- Compare commands for consistency (CONS-*)
- Detect drift from ADRs/templates

### Phase 4: Create Master Validation Command

**File**: `commands/session/validate.md` (enhance existing)

The existing `/s2s:session:validate` command should be enhanced to:
1. Run all STR-* checks by default
2. Support `--full` to run all categories
3. Support `--resume` to focus on RES-* checks
4. Support `--instructions` to run INST-* checks
5. Output structured report with evidence

### Phase 5: Create CI-style Test Runner

**File**: `commands/test.md`

New command `/s2s:test` that:
1. Creates temporary test environment
2. Runs specific workflow with --diagnostic --verbose
3. Introduces artificial interruptions at each critical point
4. Verifies resume works correctly
5. Cleans up test artifacts

---

## Detailed Check Implementation

### STR-003: Artifacts Consistency

```yaml
check: STR-003
name: Artifacts Consistency
severity: error

logic: |
  1. Read session file
  2. For each round in rounds[]:
     - Extract artifacts_created[]
  3. Flatten all artifact IDs
  4. For each ID:
     - Parse type from prefix (REQ-*, OQ-*, etc.)
     - Verify key exists in artifacts.{type}
  5. Report missing artifacts

evidence:
  - rounds[].artifacts_created (aggregated)
  - artifacts.{type} keys (all types)
  - discrepancies (if any)
```

### RES-001: agent_id Persistence

```yaml
check: RES-001
name: Agent ID Persistence
severity: error

logic: |
  1. Read session file
  2. Check agent_state.facilitator.agent_id
  3. IF rounds_completed > 0 AND agent_id is null:
     - Error: facilitator agent_id not persisted
  4. Check agent_state.participants.{id}.agent_id for each
  5. IF any participant has null agent_id AND has responded:
     - Warning: participant agent_id not persisted

evidence:
  - agent_state.facilitator
  - agent_state.participants
  - comparison with rounds[].participant_positions
```

### CTX-002: Artifact Content Propagation

```yaml
check: CTX-002
name: Artifact Content Propagation
severity: warning

logic: |
  1. Read verbose dump for facilitator question
  2. Extract participant_context.shared.relevant_artifacts
  3. For each artifact:
     - Verify has: id, title, state, description
     - Verify has type-specific fields (acceptance for REQ, etc.)
  4. Compare with artifacts in session file
  5. Report truncated/missing fields

evidence:
  - Facilitator dump participant_context
  - Session file artifact content
  - Field comparison results
```

---

## Test Scenarios

### Scenario 1: Clean Resume After Round 2

**Setup**:
1. Start `/s2s:specs --verbose`
2. Let it complete 2 rounds
3. Interrupt (Ctrl+C)
4. Resume with `/s2s:specs` (auto-detect)

**Verify**:
- [ ] Session detected as active
- [ ] Rounds 1-2 preserved in session file
- [ ] Round 3 starts (not repeats 2)
- [ ] Facilitator receives correct session_state
- [ ] Participant context includes rounds 1-2 synthesis

### Scenario 2: Resume During Participant Responses

**Setup**:
1. Start `/s2s:specs --verbose --interactive`
2. Let facilitator question complete
3. Interrupt during participant responses
4. Resume

**Verify**:
- [ ] agent_state.facilitator has agent_id
- [ ] Some participant responses may be lost (acceptable)
- [ ] Round can restart from facilitator question
- [ ] No duplicate artifacts created

### Scenario 3: Resume After Synthesis, Before Artifacts

**Setup**:
1. Start `/s2s:specs --verbose`
2. Wait for synthesis to return
3. Interrupt during artifact processing
4. Resume

**Verify**:
- [ ] Facilitator synthesis is saved (in verbose dump)
- [ ] Artifacts may be partially written
- [ ] Resume detects incomplete round
- [ ] Artifacts not duplicated on retry

---

## Existing Issues to Investigate

### Issue 1: roundtable.md vs Inline Commands

`roundtable.md` delegates to `roundtable-execution` skill but:
- Skill has less resume detail than specs/design/brainstorm
- No explicit agent_state handling in skill
- Diagnostic mode added via separate file, not integrated

**Action**: Verify if roundtable.md needs enhanced resume instructions or if skill provides sufficient guidance.

### Issue 2: Verbose Dump Completeness

The verbose dumps are critical for resume, but:
- No validation that all expected files exist
- No check that content is complete (not truncated)
- participant_context may be summarized vs full

**Action**: Add STR-009 validation and CTX-* checks.

### Issue 3: Error Recovery Gaps

`error-handling.md` is minimal:
- No recovery for mid-artifact-write failure
- No validation after recovery
- No mechanism to mark round as "partial"

**Action**: Enhance error-handling.md with specific recovery steps.

---

## Next Steps

1. **Review roundtable.md vs skill**: Determine if resume gap exists
2. **Implement STR-* checks**: Start with s2s-session-validator agent
3. **Test RES-* manually**: Run interruption scenarios
4. **Enhance /s2s:session:validate**: Add new check categories
5. **Document in BACKLOG.md**: Create TEST-003 for this work

---

## Appendix: Session File Fields for Resume

Fields that MUST be present for successful resume:

```yaml
# Required for session identification
id: "{session-id}"
status: "active"
workflow_type: "{specs|design|brainstorm|roundtable}"
strategy: "{strategy}"

# Required for resume context
agent_state:
  facilitator:
    agent_id: "{id}"       # Can resume facilitator agent
    last_round: N          # Know where we are
    last_action: "synthesis"  # Know what was last done
  participants:
    {participant-id}:
      agent_id: "{id}"     # Can resume participant agent
      last_round: N

# Required for session_state reconstruction
artifacts:
  requirements: {...}       # Full content, not just IDs
  conflicts: {...}
  open_questions: {...}

# Required for agenda/focus decisions
agenda:
  - topic_id: "..."
    status: "open|partial|closed"
    coverage: [...]

# Required for round history
rounds:
  - round: N
    topic_id: "..."
    synthesis_summary: "..."
    artifacts_created: [...]

# Required for constraint enforcement
metrics:
  rounds_completed: N
```

---

## Appendix: Backlog Item Template

```markdown
### TEST-003: Session Resilience Verification Suite

**Status**: planned | **Created**: 2026-01-18 | **Priority**: High

**Context**: Roundtable sessions can be interrupted at various points. Need comprehensive verification that resume works correctly.

**Specification**: `.s2s/plans/20260118-session-resilience-verification.md`

**Tasks**:
1. [ ] Create s2s-session-validator agent (STR-* checks)
2. [ ] Create s2s-resume-tester agent (RES-* checks)
3. [ ] Create s2s-instruction-analyzer agent (INST-* checks)
4. [ ] Enhance /s2s:session:validate command
5. [ ] Create /s2s:test command for automated scenarios
6. [ ] Document edge cases and recovery patterns

**Acceptance Criteria**:
- [ ] All STR-* checks pass on valid session files
- [ ] Resume works from all 7 interruption points
- [ ] Commands are consistent (CONS-* checks)
- [ ] Instructions follow guidelines (INST-* checks)
```
